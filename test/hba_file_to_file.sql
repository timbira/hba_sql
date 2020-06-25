BEGIN;

UPDATE  hba_sql.file
SET     user_name = '{all,bolinhaDeMeuDeus}'::text[]
WHERE   line_number = 88;

SELECT hba_sql.apply_hba_conf();

ROLLBACK;