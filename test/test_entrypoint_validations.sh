#!/bin/bash

# |  USER  |  PASS  |  DB  |  ADMIN  |  VALID  |
# | :----- | :----- | :--- | :------ | :------ |
# |  -     |  -     |  -   |  -      |  -      |
# |  -     |  -     |  -   |  +      |  +      |
# |  -     |  -     |  +   |  -      |  -      |
# |  -     |  -     |  +   |  +      |  +      |
# |  -     |  +     |  -   |  -      |  -      |
# |  -     |  +     |  -   |  +      |  -      |
# |  -     |  +     |  +   |  -      |  -      |
# |  -     |  +     |  +   |  +      |  -      |
# |  +     |  -     |  -   |  -      |  -      |
# |  +     |  -     |  -   |  +      |  -      |
# |  +     |  -     |  +   |  -      |  -      |
# |  +     |  -     |  +   |  +      |  -      |
# |  +     |  +     |  -   |  -      |  -      |
# |  +     |  +     |  -   |  +      |  +      |
# |  +     |  +     |  +   |  -      |  +      |
# |  +     |  +     |  +   |  +      |  +      |

function ci_case_entrypoint_validations() {
    local -r TEST_CASE=entrypoint_validations

    echo " ---> Testing invalid environment variable combinations"

    echo " ------> No environment variable set"
    ci_assert_container_fails

    echo " ------> Set environment variables: POSTGRESQL_DATABASE"
    ci_assert_container_fails \
        -e POSTGRESQL_DATABASE=db

    echo " ------> Set environment variables: POSTGRESQL_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_PASSWORD=pass

    echo " ------> Set environment variables: POSTGRESQL_PASSWORD, POSTGRESQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: POSTGRESQL_PASSWORD, POSTGRESQL_DATABASE"
    ci_assert_container_fails \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db

    echo " ------> Set environment variables: POSTGRESQL_PASSWORD, POSTGRESQL_DATABASE, POSTGRESQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: POSTGRESQL_USER"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user

    echo " ------> Set environment variables: POSTGRESQL_USER, POSTGRESQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: POSTGRESQL_USER, POSTGRESQL_DATABASE"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_DATABASE=db

    echo " ------> Set environment variables: POSTGRESQL_USER, POSTGRESQL_DATABASE, POSTGRESQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> Set environment variables: POSTGRESQL_USER, POSTGRESQL_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_PASSWORD=pass

    echo " ------> Set environment variables: POSTGRESQL_USER(postgres), POSTGRESQL_PASSWORD, POSTGRESQL_DATABASE, POSTGRESQL_ADMIN_PASSWORD"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=postgres \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass


    echo " ---> Testing invalid environment variable values"
    local VERY_LONG_IDENTIFIER="very_long_identifier_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

    echo " ------> [ POSTGRESQL_USER ] Invalid character"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=0invalid \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ POSTGRESQL_USER ] Too long"
    ci_assert_container_fails \
        -e POSTGRESQL_USER="${VERY_LONG_IDENTIFIER}" \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ POSTGRESQL_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_PASSWORD="\"" \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ POSTGRESQL_DATABASE ] Invalid character"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=0invalid \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ POSTGRESQL_DATABASE ] Too long"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE="${VERY_LONG_IDENTIFIER}" \
        -e POSTGRESQL_ADMIN_PASSWORD=adminpass

    echo " ------> [ POSTGRESQL_ADMIN_PASSWORD ] Invalid character"
    ci_assert_container_fails \
        -e POSTGRESQL_USER=user \
        -e POSTGRESQL_PASSWORD=pass \
        -e POSTGRESQL_DATABASE=db \
        -e POSTGRESQL_ADMIN_PASSWORD="\""
}

function ci_case_entrypoint_validations_desc() {
    echo "container entrypoint validations tests"
}
