#!/bin/bash

[ -n "${TESTDIR:-}" ] || \
    ( echo "Test suite source directory is not set!" && exit 1 )
[ -n "${COMMONDIR:-}" ] || \
    ( echo "Common tests source directory is not set!" && exit 1 )

function ci_cleanup() {
    echo "Cleaning up test containers and files ..."

    local cidfile
    for cidfile in "${CIDFILEDIR}"/*; do
        ci_container_cleanup "$( cat "${cidfile}" )"
        echo "        -> Removing container cidfile"
        rm "${cidfile}"
        echo "        -> DONE!"
    done

    echo "    Removing cidfile directory ..."
    rmdir "${CIDFILEDIR}"
    echo "        -> DONE!"

    echo "Cleaning up test container volumes ..."

    local volfile
    for volfile in "${VOLFILEDIR}"/*; do
        ci_volume_cleanup "$( cat "${volfile}" )"
        echo "        -> Removing volume volfile"
        rm "${volfile}"
        echo "        -> DONE!"
    done

    echo "    Removing volfile directory ..."
    rmdir "${VOLFILEDIR}"
    echo "        -> DONE!"
}

function ci_cleanup_disable() {
    trap - EXIT SIGINT
}

function ci_cleanup_enable() {
    trap ci_cleanup EXIT SIGINT
}

function ci_container_cleanup() {
    local cid="$1"; shift
    echo "    Cleaning up container ${cid} ..."

    echo "        -> Stopping container"
    docker stop "${cid}" >/dev/null

    local exit_status; exit_status="$( docker inspect -f '{{ .State.ExitCode }}' "${cid}" )"
    if [ ${exit_status} -ne 0 ]; then
        echo "        -> Inspecting container"
        docker inspect "${cid}"

        echo "        -> Dumping logs"
        docker logs "${cid}"
    fi

    echo "        -> Removing container"
    docker rm -v "${cid}" >/dev/null
}

function ci_container_create() {
    local name="$1"; shift

    docker run --cidfile "${CIDFILEDIR}/${name}" -d "$@" "${IMAGE_NAME}" >/dev/null
}

function ci_container_get_cid() {
    local name="$1"; shift

    echo $( cat "${CIDFILEDIR}/${name}" )
}

function ci_container_get_ip() {
    local container="$1"; shift

    docker inspect -f '{{ .NetworkSettings.IPAddress }}' "$( ci_container_get_cid "${container}" )"
}

function ci_container_stop() {
    local container="$1"; shift

    docker stop "$( ci_container_get_cid "${container}" )" >/dev/null
}

function ci_initialize() {
    local test_suite="$1"; shift

    readonly TEST_SUITE_NAME="${test_suite}"
    readonly CIDFILEDIR="$( mktemp --directory --tmpdir "${TEST_SUITE_NAME}_cidfiledir.XXXXXX" )"
    readonly VOLFILEDIR="$( mktemp --directory --tmpdir "${TEST_SUITE_NAME}_volfiledir.XXXXXX" )"

    ci_cleanup_enable
}

function ci_volume_cleanup() {
    local volume_dir="$1"; shift

    echo "    Cleaning up volume ${volume_dir} ..."

    echo "        -> Removing files created by contianer"
    docker run --rm -v "${volume_dir}:/tmp/volume-cleanup:Z" "${IMAGE_NAME}" \
        bash -c 'find /tmp/volume-cleanup/ -uid 26 -delete'

    echo "        -> Removing volume directory"
    rm -rf "${volume_dir}"
}

function ci_volume_create() {
    local name="$1"; shift

    local volume_dir; volume_dir="$( mktemp --directory --tmpdir "${TEST_SUITE_NAME}_volume.XXXXXX" )"
    setfacl -m u:26:rwx "${volume_dir}"

    echo "${volume_dir}" > "${VOLFILEDIR}/${name}"
    echo "${volume_dir}"
}

function ci_volume_get_dir() {
    local name="$1"; shift

    echo "$( cat "${VOLFILEDIR}/${name}" )"
}

function ci_secret_create() {
    local volume="$1"; shift
    local secret_name="$1"; shift
    local secret_value="$1"; shift
    local secret_file="${volume}/${secret_name}"

    [ "." == "$( dirname "${secret_name}" )" ] \
        || mkdir -p "$( dirname "${secret_file}" )"

    echo "${secret_value}" > "${secret_file}"
}

function ci_suite_execute() {
    local test_suite="$@"
    local test_suite_length="$#"

    local i=1
    local test_case_cmd
    local test_case_desc
    for test_case in ${test_suite}; do
        ci_suite_load_case "${test_case}"
        test_case_cmd="ci_case_${test_case}"
        test_case_desc="$( ${test_case_cmd}_desc )"

        echo "Test case $(( i++ ))/${test_suite_length} : Running ${test_case_desc}"
        ${test_case_cmd}
    done
}

function ci_suite_list() {
    local test_suite="$@"

    local test_case_desc
    for test_case in ${test_suite}; do
        ci_suite_load_case "${test_case}"
        test_case_desc="$( ci_case_${test_case}_desc )"

        printf "  %-30s   %s\n" "${test_case}" "${test_case_desc}"
    done
}

function ci_suite_load_case() {
    local test_case="$1"; shift

    [ -f "${TESTDIR}/test_${test_case}.sh" ] && \
        source "${TESTDIR}/test_${test_case}.sh"
}
