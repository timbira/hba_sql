BEGIN;

CREATE SCHEMA hba_sql;

CREATE TABLE hba_sql.file AS
SELECT
    *
FROM
    pg_hba_file_rules;

CREATE OR REPLACE FUNCTION hba_sql.apply_hba_conf()
RETURNS BOOLEAN
AS
$$
DECLARE 
    hba_file_path       TEXT := current_setting('hba_file');
    current_hba_content TEXT := pg_read_file(hba_file_path);
    statement           TEXT;
    has_error           BOOLEAN := false;
    hba_error           RECORD;
BEGIN

    statement :=
        format(
            '%s', 
            $SQL$
            COPY (
                SELECT  format('%s %s %s %s %s %s %s',
                            type, 
                            array_to_string(database, ','), 
                            array_to_string(user_name, ','), 
                            address,
                            netmask,
                            auth_method,
                            array_to_string(options, ',')
                        ) 
                FROM    hba_sql.file
            ) TO $SQL$ || quote_literal(hba_file_path));

    RAISE INFO '%', statement;
    EXECUTE statement;

    PERFORM pg_reload_conf();

    FOR hba_error IN
        SELECT  line_number, error
        FROM    pg_hba_file_rules
        WHERE   error IS NOT NULL
    LOOP
        RAISE INFO 'Line number: %, ERROR: %', hba_error.line_number, hba_error.error;
        has_error := true;
    END LOOP;

    IF has_error IS TRUE THEN
        statement := format(
            $SQL$COPY (SELECT * FROM unnest(string_to_array(%L, chr(10)))) TO %L$SQL$, current_hba_content, hba_file_path);
        RAISE INFO '%', statement;
        EXECUTE statement;
        PERFORM pg_reload_conf();
    END IF;

    RETURN (NOT has_error);
END;
$$
LANGUAGE plpgsql;

COMMIT;