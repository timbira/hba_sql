# GIVEN pg_hba_file_rules THEN CREATE TABLE


# GIVEN TABLE hba_file THEN GENERATE FILE '$PGDATA/pg_hba.conf'


# 1 - BACKUP CURRENT HBA
# 2 - GENERATE NEW HBA FILE
# 3 - RELOAD PG
# 4 - VALIDATE HBA USING VIEW pg_hba_file_rules
    # BAD - ROLLBACK
    # OK - DONE

# PG_HBA_FILE VERSIONING
