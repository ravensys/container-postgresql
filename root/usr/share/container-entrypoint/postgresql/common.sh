#!/bin/bash

export POSTGRESQL_CONFIG_FILE="/var/lib/pgsql/data/postgresql-container.conf"
export POSTGRESQL_DATADIR="/var/lib/pgsql/data/pgdata"

postgresql_identifier_regex='^[a-zA-Z_][a-zA-Z0-9_]*$'
postgresql_password_regex='^[a-zA-Z0-9_~!@#$%^&*()-=<>,.?;:|]+$'

function get_secret_mapping() {
    local variable="$1"; shift

    case "${variable}" in
        "POSTGRESQL_ADMIN_PASSWORD" )
            echo postgresql/admin_password ;;
        "POSTGRESQL_DATABASE" )
            echo postgresql/database ;;
        "POSTGRESQL_PASSWORD" )
            echo postgresql/password ;;
        "POSTGRESQL_USER" )
            echo postgresql/user ;;
        * )
            echo "${variable}" ;;
    esac
}

function postgresql_cleanup_environment() {
    unset POSTGRESQL_ADMIN_PASSWORD \
          POSTGRESQL_DATABASE \
          POSTGRESQL_PASSWORD \
          POSTGRESQL_USER
}

function postgresql_create_database() {
    local database="$1"; shift

    psql --set database="${database}" <<EOSQL
CREATE DATABASE :"database";
EOSQL
}

function postgresql_create_database_if_not_exists() {
    local database="$1"; shift

    if ! postgresql_has_database "${database}"; then
        postgresql_create_database "${database}"
    fi
}

function postgresql_create_user() {
    local user="$1"; shift

    psql --set user="${user}" <<EOSQL
CREATE USER :"user";
EOSQL
}

function postgresql_create_user_if_not_exists() {
    local user="$1"; shift

    if ! postgresql_has_user "${user}"; then
        postgresql_create_user "${user}"
    fi
}

function postgresql_drop_database() {
    local database="$1"; shift

    psql --set database="${database}" <<EOSQL
DROP DATABASE IF EXISTS :"database";
EOSQL
}

function postgresql_drop_user() {
    local user="$1"; shift

    psql --set user="${user}" <<EOSQL
DROP USER IF EXISTS :"user";
EOSQL
}

function postgresql_export_config_variables() {
    export POSTGRESQL_MAX_CONNECTIONS=${POSTGRESQL_MAX_CONNECTIONS:-100}
    export POSTGRESQL_MAX_PREPARED_TRANSACTIONS=${POSTGRESQL_MAX_PREPARED_TRANSACTIONS:-0}

    local CGROUP_MEMORY_LIMIT_IN_BYTES=$( cgroup_get_memory_limit_in_bytes )

    if [ -n "${CGROUP_MEMORY_LIMIT_IN_BYTES}" ] &&  [ ${CGROUP_MEMORY_LIMIT_IN_BYTES} -gt 0 ]; then
        export POSTGRESQL_EFFECTIVE_CACHE_SIZE=${POSTGRESQL_EFFECTIVE_CACHE_SIZE:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/2 ))MB}
        export POSTGRESQL_MAINTENANCE_WORK_MEM=${POSTGRESQL_MAINTENANCE_WORK_MEM:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/8 ))MB}
        export POSTGRESQL_SHARED_BUFFERS=${POSTGRESQL_SHARED_BUFFERS:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/1024/4 ))MB}
        export POSTGRESQL_WORK_MEM=${POSTGRESQL_WORK_MEM:-$(( CGROUP_MEMORY_LIMIT_IN_BYTES/1024/4/POSTGRESQL_MAX_CONNECTIONS ))kB}
    else
        export POSTGRESQL_EFFECTIVE_CACHE_SIZE=${POSTGRESQL_EFFECTIVE_CACHE_SIZE:-128MB}
        export POSTGRESQL_MAINTENANCE_WORK_MEM=${POSTGRESQL_MAINTENANCE_WORK_MEM:-32MB}
        export POSTGRESQL_SHARED_BUFFERS=${POSTGRESQL_SHARED_BUFFERS:-64MB}
        export POSTGRESQL_WORK_MEM=${POSTGRESQL_WORK_MEM:-640kB}
    fi
}

function postgresql_generate_config() {
    envsubst \
        < "${CONTAINER_ENTRYPOINT_PATH}/postgresql/postgresql-container.conf.template" \
        > "${POSTGRESQL_CONFIG_FILE}"
}

function postgresql_has_database() {
    local database="$1"; shift

    psql --no-align --tuples-only --set database="${database}" <<EOSQL | grep -q 1
SELECT 1 FROM pg_database WHERE datname = :'database'
EOSQL
}

function postgresql_has_user() {
    local user="$1"; shift

    psql --no-align --tuples-only --set user="${user}" <<EOSQL | grep -q 1
SELECT 1 FROM pg_roles WHERE rolname = :'user'
EOSQL
}

function postgresql_initialize() {
    LANG=${LANG:-en_US.UTF-8} pg_ctl -D "${POSTGRESQL_DATADIR}" initdb

    cat >> "${POSTGRESQL_DATADIR}/postgresql.conf" <<EOCONF

#
# Container specific configuration
#

include '${POSTGRESQL_CONFIG_FILE}'
EOCONF

    cat >> "${POSTGRESQL_DATADIR}/pg_hba.conf" <<EOCONF

#
# Container authentication override
#

host    all             all             all                 md5
EOCONF

    postgresql_start_local

    local postgresql_user; postgresql_user="$( get_value POSTGRESQL_USER postgres )"
    if [ -n "${postgresql_user}" ] && [ "postgres" != "${postgresql_user}" ]; then
        postgresql_create_user "${postgresql_user}"
    fi

    local postgresql_database; postgresql_database="$( get_value POSTGRESQL_DATABASE '' )"
    if [ -n "${postgresql_database}" ]; then
        postgresql_create_database "${postgresql_database}"
        postgresql_set_owner "${postgresql_database}" "${postgresql_user}"
    fi
}

function postgresql_is_initialized() {
    [ -f "${POSTGRESQL_DATADIR}/PG_VERSION" ]
}

function postgresql_set_owner() {
    local database="$1"; shift
    local user="$1"; shift

    psql --set database="${database}" --set user="${user}" <<EOSQL
ALTER DATABASE :"database" OWNER TO :"user";
EOSQL
}

function postgresql_set_password() {
    local user="$1"; shift
    local password="$1"; shift

    psql --set user="${user}" --set password="${password}" <<EOSQL
ALTER USER :"user" WITH ENCRYPTED PASSWORD :'password';
EOSQL
}

function postgresql_start_local() {
    pg_ctl -D "${POSTGRESQL_DATADIR}" -o "-h ''" -w start
}

function postgresql_stop_local() {
    pg_ctl -D "${POSTGRESQL_DATADIR}" -w stop
}
