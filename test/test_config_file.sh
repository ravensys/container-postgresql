#!/bin/bash

function ci_case_config_file() {
    local -r TEST_CASE=config_file

    echo " ---> Testing non-default values for configuration options"
    POSTGRESQL_EFFECTIVE_CACHE_SIZE=200MB
    POSTGRESQL_MAINTENANCE_WORK_MEM=60MB
    POSTGRESQL_MAX_CONNECTIONS=20
    POSTGRESQL_MAX_PREPARED_TRANSACTIONS=10
    POSTGRESQL_SHARED_BUFFERS=100MB
    POSTGRESQL_WORK_MEM=2MB

    ci_postgresql_container "${TEST_CASE}_nondefault" testuser testpass \
        -e POSTGRESQL_USER=testuser \
        -e POSTGRESQL_PASSWORD=testpass \
        -e POSTGRESQL_DATABASE=testdb \
        -e POSTGRESQL_EFFECTIVE_CACHE_SIZE="${POSTGRESQL_EFFECTIVE_CACHE_SIZE}" \
        -e POSTGRESQL_MAINTENANCE_WORK_MEM="${POSTGRESQL_MAINTENANCE_WORK_MEM}" \
        -e POSTGRESQL_MAX_CONNECTIONS="${POSTGRESQL_MAX_CONNECTIONS}" \
        -e POSTGRESQL_MAX_PREPARED_TRANSACTIONS="${POSTGRESQL_MAX_PREPARED_TRANSACTIONS}" \
        -e POSTGRESQL_SHARED_BUFFERS="${POSTGRESQL_SHARED_BUFFERS}" \
        -e POSTGRESQL_WORK_MEM="${POSTGRESQL_WORK_MEM}"

    echo " ------> Testing PostgreSQL configuration"
    ci_assert_configuration "${TEST_CASE}_nondefault"


    echo " ---> Testing configuration auto-tuning capabilities"
    ci_postgresql_config_defaults
    POSTGRESQL_EFFECTIVE_CACHE_SIZE=256MB
    POSTGRESQL_MAINTENANCE_WORK_MEM=64MB
    POSTGRESQL_SHARED_BUFFERS=128MB
    POSTGRESQL_WORK_MEM=1310kB

    ci_postgresql_container "${TEST_CASE}_autotune" testuser testpass \
        -e POSTGRESQL_USER=testuser \
        -e POSTGRESQL_PASSWORD=testpass \
        -e POSTGRESQL_DATABASE=testdb \
        -m 512M

    echo " ------> Testing PostgreSQL configuration"
    ci_assert_configuration "${TEST_CASE}_autotune"
}

function ci_case_config_file_desc() {
    echo "container PostgreSQL configuration file tests"
}
