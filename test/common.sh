#!/bin/bash

[ -n "${TESTDIR:-}" ] || \
    ( echo "Test suite source directory is not set!" && exit 1 )
[ -n "${COMMONDIR:-}" ] || \
    ( echo "Common tests source directory is not set!" && exit 1 )

function ci_postgresql_build_envs() {
    local docker_args

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        docker_args+=" -e POSTGRESQL_ADMIN_PASSWORD=${TEST_ADMIN_PASSWORD}"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        docker_args+=" -e POSTGRESQL_USER=${TEST_USER}"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        docker_args+=" -e POSTGRESQL_PASSWORD=${TEST_PASSWORD}"
    fi

    docker_args+=" -e POSTGRESQL_DATABASE=testdb"

    echo "${docker_args}"
}

function ci_postgresql_build_secrets() {
    local secrets_volume="$1"; shift
    local secrets_prefix="${1:-postgresql/}"
    local docker_args=" -v ${secrets_volume}:/run/secrets"

    if [ -n "${TEST_ADMIN_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}admin_password" "${TEST_ADMIN_PASSWORD}"
        [ "postgresql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e POSTGRESQL_ADMIN_PASSWORD_SECRET=${secrets_prefix}admin_password"
    fi

    if [ -n "${TEST_USER:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}user" "${TEST_USER}"
        [ "postgresql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e POSTGRESQL_USER_SECRET=${secrets_prefix}user"
    fi

    if [ -n "${TEST_PASSWORD:-}" ]; then
        ci_secret_create "${secrets_volume}" "${secrets_prefix}password" "${TEST_PASSWORD}"
        [ "postgresql/" == "${secrets_prefix}" ] || \
            docker_args+=" -e POSTGRESQL_PASSWORD_SECRET=${secrets_prefix}password"
    fi

    ci_secret_create "${secrets_volume}" "${secrets_prefix}database" testdb
    [ "postgresql/" == "${secrets_prefix}" ] || \
        docker_args+=" -e POSTGRESQL_DATABASE_SECRET=${secrets_prefix}database"

    echo "${docker_args}"
}

function ci_postgresql_cmd() {
    local ip="$1"; shift
    local user="$1"; shift
    local pass="$1"; shift

    docker run --rm -e PGPASSWORD="${pass}" "${IMAGE_NAME}" \
        psql "postgresql://${user}@${ip}:5432/testdb" "$@"
}

function ci_postgresql_config_defaults() {
    POSTGRESQL_EFFECTIVE_CACHE_SIZE=128MB
    POSTGRESQL_MAINTENANCE_WORK_MEM=32MB
    POSTGRESQL_MAX_CONNECTIONS=100
    POSTGRESQL_MAX_PREPARED_TRANSACTIONS=0
    POSTGRESQL_SHARED_BUFFERS=64MB
    POSTGRESQL_WORK_MEM=640kB
}

function ci_postgresql_container() {
    local container="$1"; shift
    local user="$1"; shift
    local password="$1"; shift

    echo " ------> Creating PostgreSQL container [ ${container} ]"
    ci_container_create "${container}" "$@"

    echo " ------> Verifying initial connection to container as ${user}(${password})"
    ci_postgresql_wait_connection "${container}" "${user}" "${password}"
}

function ci_postgresql_wait_connection() {
    local container="$1"; shift
    local user="$1"; shift
    local pass="$1"; shift
    local max_attempts="${1:-20}"

    local i
    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    for i in $( seq ${max_attempts} ); do
        echo " ------> Connection attempt to container [ ${container} ] < ${i} / ${max_attempts} >"
        if ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "SELECT 1;"; then
            return
        fi
        sleep 2
    done

    exit 1
}

function ci_assert_config_option() {
    local container="$1"; shift
    local option_name="$1"; shift
    local option_value="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        grep -qx "${option_name} = ${option_value}" /var/lib/pgsql/data/postgresql-container.conf
}

function ci_assert_configuration() {
    local container="$1"; shift

    ci_assert_config_option "${container}" effective_cache_size "${POSTGRESQL_EFFECTIVE_CACHE_SIZE}"
    ci_assert_config_option "${container}" maintenance_work_mem "${POSTGRESQL_MAINTENANCE_WORK_MEM}"
    ci_assert_config_option "${container}" max_connections "${POSTGRESQL_MAX_CONNECTIONS}"
    ci_assert_config_option "${container}" max_prepared_transactions "${POSTGRESQL_MAX_PREPARED_TRANSACTIONS}"
    ci_assert_config_option "${container}" shared_buffers "${POSTGRESQL_SHARED_BUFFERS}"
    ci_assert_config_option "${container}" work_mem "${POSTGRESQL_WORK_MEM}"
}

function ci_assert_container_fails() {
    local ret=0
    timeout -s 9 --preserve-status 60s docker run --rm "$@" "${IMAGE_NAME}" || ret=$?

    [ ${ret} -lt 100 ] || \
        exit 1
}

function ci_assert_local_access() {
    local container="$1"; shift

    docker exec $( ci_container_get_cid "${container}" ) \
        bash -c 'psql <<< "SELECT 1;"'
}

function ci_assert_login_access() {
    local container="$1"; shift
    local user="$1"; shift
    local pass="$1"; shift
    local success="$1"; shift

    if ci_postgresql_cmd $( ci_container_get_ip "${container}" ) "${user}" "${pass}" <<< "SELECT 1;"; then
        if $success; then
            echo "${user}(${pass}) access granted as expected."
            return
        fi
    else
        if ! $success; then
            echo "${user}(${pass}) access denied as expected."
            return
        fi
    fi

    echo "${user}(${pass}) login assertion failed."
    exit 1
}

function ci_assert_postgresql() {
    local container="$1"; shift
    local user="$1"; shift
    local pass="$1"; shift

    local container_ip; container_ip="$( ci_container_get_ip "${container}" )"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "CREATE EXTENSION 'uuid-ossp';"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "CREATE TABLE testtbl (testcol1 VARCHAR(20), testcol2 VARCHAR(20));"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "INSERT INTO testtbl VALUES('foo1', 'bar1');"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "INSERT INTO testtbl VALUES('foo2', 'bar2');"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "SELECT * FROM testtbl;"
    ci_postgresql_cmd "${container_ip}" "${user}" "${pass}" <<< "DROP TABLE testtbl;"
}
