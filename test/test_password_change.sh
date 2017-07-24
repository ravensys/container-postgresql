#!/bin/bash

function ci_case_password_change() {
    local -r TEST_CASE=password_change

    echo " ---> Creating PostgreSQL data volume"
    local pgdata_volume; pgdata_volume="$( ci_volume_create "${TEST_CASE}_pgdata" )"

    echo " ---> Creating initial container"
    ci_postgresql_container "${TEST_CASE}_initial" testuser foo \
        -e POSTGRESQL_USER=testuser \
        -e POSTGRESQL_PASSWORD=foo \
        -e POSTGRESQL_DATABASE=testdb \
        -e POSTGRESQL_ADMIN_PASSWORD=fooadmin \
        -v "${pgdata_volume}:/var/lib/pgsql/data:Z"

    echo " ------> Testing connection to container as admin"
    ci_assert_login_access "${TEST_CASE}_initial" postgres fooadmin true

    echo " ------> Stopping initial container [ ${TEST_CASE}_initial ]"
    ci_container_stop "${TEST_CASE}_initial"


    echo " ---> Creating container with updated passwords"
    ci_postgresql_container "${TEST_CASE}_updated" testuser bar \
        -e POSTGRESQL_USER=testuser \
        -e POSTGRESQL_PASSWORD=bar \
        -e POSTGRESQL_DATABASE=testdb \
        -e POSTGRESQL_ADMIN_PASSWORD=baradmin \
        -v "${pgdata_volume}:/var/lib/pgsql/data:Z"

    echo " ------> Testing connection to container as admin (with updated credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" postgres baradmin true

    echo " ------> Testing connection to container as unprivileged user (with initial credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" testuser foo false

    echo " ------> Testing connection to container as admin (with initial credentials)"
    ci_assert_login_access "${TEST_CASE}_updated" postgres fooadmin false
}

function ci_case_password_change_desc() {
    echo "PostgreSQL accounts password change tests"
}
