#!/bin/bash

function postgresql_usage() {
    [ $# -eq 1 ] && echo "$1" >&2

    cat >&2 <<EOHELP

PostgreSQL SQL database server Docker image

Environment variables (container initialization):
  POSTGRESQL_ADMIN_PASSWORD     Password for the admin \`postgres\` account
  POSTGRESQL_DATABASE           Name of database to be created
  POSTGRESQL_PASSWORD           Password for the user account
  POSTGRESQL_USER               Name of user to be created

Environment variables (postgresql configuration):

  POSTGRESQL_EFFECTIVE_CACHE_SIZE       Sets the planner's assumption about the effective size of the disk cache that
                                        is available to a single query.
  POSTGRESQL_MAINTENANCE_WORK_MEM       Specifies the maximum amount of memory to be used by maintenance operations,
                                        such as VACUUM, CREATE INDEX, and ALTER TABLE ADD FOREIGN KEY.
  POSTGRESQL_MAX_CONNECTIONS            The maximum number of concurrent connections to the database server.
  POSTGRESQL_MAX_PREPARED_TRANSACTIONS  Sets the maximum number of transactions that can be in the "prepared" state
                                        simultaneously. Setting this parameter to zero disables the
                                        prepared-transaction feature.
  POSTGRESQL_SHARED_BUFFERS             Sets the amount of memory the database server uses for shared memory buffers.
  POSTGRESQL_WORK_MEM                   Specifies the amount of memory to be used by internal sort operations and hash
                                        tables before writing to temporary disk files.

Secrets:
  postgresql/admin_password     Password for the admin \`postgres\` account
                                (environment variable: POSTGRESQL_ADMIN_PASSWORD_SECRET)
  postgresql/database           Name of database to be created
                                (environment variable: POSTGRESQL_DATABASE_SECRET)
  postgresql/password           Password for the user account
                                (environment variable: POSTGRESQL_PASSWORD_SECRET)
  postgresql/user               Name of user to be created
                                (environment variable: POSTGRESQL_USER_SECRET)

Volumes:
  /var/lib/pgsql/data   PostgreSQL data directory

For more information see /usr/share/container-scripts/postgresql/README.md within container
or visit <https://github.com/ravensys/container-postgresql>.
EOHELP

    exit 1
}

function postgresql_validate_variables() {
    local user_specified=0
    local root_specified=0

    local postgresql_admin_password; postgresql_admin_password="$( get_value POSTGRESQL_ADMIN_PASSWORD '' )"
    local postgresql_database; postgresql_database="$( get_value POSTGRESQL_DATABASE '' )"
    local postgresql_password; postgresql_password="$( get_value POSTGRESQL_PASSWORD '' )"
    local postgresql_user; postgresql_user="$( get_value POSTGRESQL_USER '' )"

    if [ -n "${postgresql_user}" ] || [ -n "${postgresql_password}" ]; then
        [[ "${postgresql_user}" =~ ${postgresql_identifier_regex} ]] || \
            postgresql_usage "Invalid PostgreSQL user (invalid character or empty)."

        [ ${#postgresql_user} -le 63 ] || \
            postgresql_usage "Invalid PostgreSQL user (too long, max. 63 characters)."

        [[ "${postgresql_password:-}" =~ ${postgresql_password_regex} ]] || \
            postgresql_usage "Invalid PostgreSQL password (invalid character or empty)."

        user_specified=1
    fi

    if [ -n "${postgresql_admin_password}" ]; then
        [[ "${postgresql_admin_password}" =~ ${postgresql_password_regex} ]] || \
            postgresql_usage "Invalid PostgreSQL admin password (invalid character or empty)."

        root_specified=1
    fi

    if [ ${user_specified} -eq 1 ] && [ "postgres" == "${postgresql_user}" ]; then
        [ ${root_specified} -eq 0 ] || \
            postgresql_usage "When POSTGRESQL_USER is set to 'postgres' admin password must be set only in POSTGRESQL_PASSWORD."

        user_specified=0
        root_specified=1
    fi

    [ ${user_specified} -eq 1 ] || [ ${root_specified} -eq 1 ] || \
        postgresql_usage

    [ ${root_specified} -eq 0 ] && [ -z "${postgresql_database}" ] && \
        postgresql_usage

    if [ -n "${postgresql_database}" ]; then
        [[ "${postgresql_database}" =~ ${postgresql_identifier_regex} ]] || \
            postgresql_usage "Invalid PostgreSQL database name (invalid character or empty)."
        [ ${#postgresql_database} -le 63 ] || \
            postgresql_usage "Invalid PostgreSQL database name (too long, max. 63 characters)."
    fi
}

postgresql_validate_variables
