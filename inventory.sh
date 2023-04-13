#!/bin/bash

if [[ -n $1 ]]; then
    SQLITE_OPTIONS=$@
fi

ANSIBLE_HOST_VARS=(ansible_host ansible_user)

SQL_CONNECT="$(which sqlite3) ansible.sqlite3 ${SQLITE_OPTIONS}"

get_groups() {
    ${SQL_CONNECT} "SELECT DISTINCT group_name FROM ansible_hosts LEFT JOIN ansible_groups ON ansible_hosts.ansible_group_id = ansible_groups.id;"
}

get_hosts_by_group() {
    # local _FILTER="WHERE group_name = 'all'"
    local _FILTER=""
    if [[ -n $1 ]]; then
        _FILTER="WHERE group_name = '$1'"
    fi
    ${SQL_CONNECT} "SELECT host_name FROM ansible_hosts LEFT JOIN ansible_groups ON ansible_hosts.ansible_group_id = ansible_groups.id ${_FILTER};"
}

get_group_vars() {
    local _FILTER="WHERE group_name = 'all'"
    if [[ -n $1 ]]; then
        _FILTER="WHERE group_name = '$1'"
    fi
    ${SQL_CONNECT} "SELECT ansible_vars FROM ansible_groups ${_FILTER};"
}

get_host_vars() {
    if [[ -n $1 && -n $2 ]]; then
        local _FILTER="WHERE host_name = '$1'"
        local _VAR=$2
        ${SQL_CONNECT} "SELECT ${_VAR} FROM ansible_hosts ${_FILTER};"
    else
        exit 1
    fi
}

for GROUP in $(get_groups); do
    for HOST in $(get_hosts_by_group ${GROUP}); do
        [[ -n ${JSON_HOST} ]] && JSON_HOST=${JSON_HOST},
        JSON_HOST=${JSON_HOST}\"${HOST}\"
    done
    GROUP_VARS=$(get_group_vars ${GROUP})
    [[ -n ${GROUP_VARS} ]] && JSON_GROUP_VARS=",\"vars\":${GROUP_VARS}"
    # [[ -n ${JSON_GROUP} ]] && JSON_GROUP=${JSON_GROUP},
    JSON_GROUP=${JSON_GROUP}${_COMMA}"\"${GROUP}\":{\"hosts\":[${JSON_HOST}]${JSON_GROUP_VARS}}"
    _COMMA=,
    unset JSON_HOST
    unset GROUP_VARS
    unset JSON_GROUP_VARS
done
unset _COMMA
for HOST in $(get_hosts_by_group); do
    HOST_META="${HOST_META}${_COMMA1}\"${HOST}\":{"
    for ANSIBLE_VAR in ${ANSIBLE_HOST_VARS[@]}; do
        HOST_META="${HOST_META}${_COMMA2}\"${ANSIBLE_VAR}\":\"$(get_host_vars ${HOST} ${ANSIBLE_VAR})\""
        _COMMA2=,
    done
    HOST_META="${HOST_META}}"
    _COMMA1=,
    unset _COMMA2
done
unset _COMMA1
unset _COMMA2
JSON_META="\"_meta\":{\"hostvars\":{${HOST_META}}}"
echo -e "{${JSON_GROUP},${JSON_META}}"
