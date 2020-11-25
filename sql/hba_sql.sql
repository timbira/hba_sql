-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION hba_sql" to load this file. \quit

CREATE SEQUENCE @extschema@.file_priority_seq
    INCREMENT BY 10 START WITH 10;

CREATE TABLE @extschema@.lines (
    data TEXT
);

CREATE TABLE @extschema@.file (
	priority        INTEGER NOT NULL DEFAULT nextval('@extschema@.file_priority_seq'),
	type 			TEXT,
	database 		TEXT[],
	user_name 		TEXT[],
	host 			TEXT,
	method 			TEXT,
	options 		TEXT,
    comments        TEXT,
    PRIMARY KEY (priority),
	--UNIQUE (type, database, user_name, host, method),
	CHECK (type IN ('local', 'host', 'hostssl', 'hostnossl', 'hostgssenc', 'hostnogssenc')),
	CHECK (method IN ('trust', 'reject', 'md5', 'password', 'scram-sha-256', 'gss', 'sspi', 'ident', 'peer', 'pam', 'ldap', 'radius', 'cert'))
);

ALTER SEQUENCE @extschema@.file_priority_seq
    OWNED BY @extschema@.file.priority;

CREATE FUNCTION @extschema@.load(hba_file TEXT DEFAULT current_setting('hba_file'), load_and_parse BOOLEAN DEFAULT TRUE)
RETURNS void
AS
$$
BEGIN
    TRUNCATE @extschema@.lines;

	EXECUTE format('COPY @extschema@.lines (data) FROM %L', hba_file);

    IF load_and_parse IS TRUE THEN
        PERFORM @extschema@.parse();
    END IF;

    RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION @extschema@.parse()
RETURNS void
AS
$$
BEGIN
    TRUNCATE @extschema@.file RESTART IDENTITY;

    INSERT INTO @extschema@.file (type, database, user_name, host, method, options, comments)
    WITH lines_parsed_1 AS (
    	SELECT
            row_number() OVER (),
    		regexp_split_to_array(data, '\s+') AS line
    	FROM
            @extschema@.lines
    	WHERE
    		trim(data) !~ '^#'
    		AND trim(data) !~ '^$'
    ),
    lines_parsed_2 AS (
        SELECT
            row_number,
        	line[1] AS type,
        	string_to_array(line[2], ',') AS database,
        	string_to_array(line[3], ',') AS user_name,
        	(CASE WHEN line[1] = 'local' THEN NULL ELSE line[4] END) AS host,
        	CASE WHEN line[1] = 'local' THEN line[4] ELSE line[5] END AS method,
            (CASE WHEN line[1] != 'local' AND line[6] !~ '^#' THEN nullif(trim(line[6]), '') ELSE NULL END) AS options,
            CASE WHEN line[1] = 'local' THEN 5 ELSE 6 END AS comment_position,
            line
        FROM
    	    lines_parsed_1
    ),
    lines_raw AS (
        SELECT
            row_number,
            type,
            database,
            user_name,
            host,
            method,
            options,
            (SELECT
                string_agg(trim(replace(line[i], '#', '')), ' ')
             FROM
                generate_series(comment_position, array_upper(line, 1)) AS i) AS comments
        FROM
            lines_parsed_2
    )
    SELECT
        type, database, user_name, host, method, options, trim(comments)
    FROM
        lines_raw
    GROUP BY
        type, database, user_name, host, method, options, trim(comments)
    ORDER BY
        min(row_number);

    RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION @extschema@.write(hba_file TEXT DEFAULT current_setting('hba_file'), backup BOOLEAN DEFAULT TRUE)
RETURNS void
AS
$$
DECLARE
    query TEXT;
BEGIN
    IF backup IS TRUE THEN
        PERFORM @extschema@.load(hba_file);
        EXECUTE 
            format(
                'COPY @extschema@.lines TO %L',
                format('%s.bkp_%s', hba_file, to_char(clock_timestamp(), 'FMYYYYMMDDHH24MISSUS')));
    END IF;

    query := $SQL$
        SELECT
            format('%s %s %s %s %s %s %s',
                type,
                array_to_string(database, ','),
                array_to_string(user_name, ','),
                host,
                method,
                options,
                '# ' || comments
            )
        FROM
            @extschema@.file
        ORDER BY
            priority
    $SQL$;

	EXECUTE format('COPY (%s) TO %L', query, hba_file);
    RETURN;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION @extschema@.get_duplicates()
RETURNS TABLE (type TEXT, database TEXT[], user_name TEXT[], host TEXT, method TEXT, count BIGINT)
AS
$$
    SELECT
        type, database, user_name, host, method, count(*)
    FROM
        @extschema@.file
    GROUP BY
        type, database, user_name, host, method
    HAVING
        count(*) > 1;
$$
LANGUAGE sql;
