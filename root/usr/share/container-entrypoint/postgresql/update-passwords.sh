#!/bin/bash

function postgresql_update_passwords() {
    local postgresql_password; postgresql_password=$( get_value POSTGRESQL_PASSWORD "" )
    if [ -n "${postgresql_password}" ]; then
        local postgresql_user; postgresql_user=$( get_value POSTGRESQL_USER )
        postgresql_set_password "${postgresql_user}" "${postgresql_password}"
    fi

    local postgresql_admin_password; postgresql_admin_password=$( get_value POSTGRESQL_ADMIN_PASSWORD "" )
    if [ -n "${postgresql_admin_password}" ]; then
        postgresql_set_password postgres "${postgresql_admin_password}"
    fi
}

postgresql_update_passwords
