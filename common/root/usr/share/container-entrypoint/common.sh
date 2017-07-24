#!/bin/bash

function cgroup_get_memory_limit_in_bytes() {
    local memory_limit_in_bytes=$( cat /sys/fs/cgroup/memory/memory.limit_in_bytes )

    if [ ${memory_limit_in_bytes} -lt 9223372035781033984 ]; then
        echo ${memory_limit_in_bytes}
    fi
}

function get_secret() {
    local variable="$1"; shift
    local secret="${variable}_SECRET"
    #local -n secret="${variable}_SECRET"

    if [ -n "${!secret:-}" ]; then
        echo "${CONTAINER_SECRETS_PATH}/${!secret}"
    elif [ "function" == "$( type -t get_secret_mapping )" ]; then
        echo "${CONTAINER_SECRETS_PATH}/$( get_secret_mapping "${variable}" )"
    else
        echo "${CONTAINER_SECRETS_PATH}/${variable}"
    fi
}

function get_value() {
    local variable="$1"; shift
    local secret="$( get_secret "${variable}" )"

    if [ -f "${secret}" ]; then
        cat "${secret}"
    elif [ -n "${!variable:-}" ]; then
        echo "${!variable}"
    elif [ $# -eq 1 ]; then
        echo "$1"
    else
        echo >&2 "${variable} is not defined"
        exit 1
    fi
}

function log_message() {
    echo "< $( date "+%F %T" ) >    $@"
}

function source_scripts() {
    local dir="$1"; shift

    local file
    for file in "${dir}"/*; do
        case "${file}" in
            *.sh)  source "${file}" ;;
        esac
    done
}
