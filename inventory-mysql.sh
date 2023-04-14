#!/bin/bash

DB_NAME="ansible_inventory"
DB_USER="liutauras"
DB_SERVER="localhost"
DB_CONN="mysql -h ${DB_SERVER} -u ${DB_USER} ${DB_NAME}"

_JSON="{}"

#SQL="
#    SELECT 
#        JSON_OBJECT(
#            group_name, 
#            JSON_OBJECT(
#                'hosts', 
#                JSON_ARRAYAGG(host_name),
#                'vars', 
#                (
#                    SELECT
#                        JSON_OBJECTAGG(
#                            ansible_var_name,
#                            ansible_var_value
#                        )
#                    FROM ansible_group_vars 
#                    WHERE ansible_group_id=1
#                )
#            )
#        ) as groups
#    FROM ansible_hosts 
#    LEFT JOIN ansible_groups 
#    ON ansible_hosts.ansible_group_id = ansible_groups.ID 
#    GROUP BY group_name
#;"
#    #WHERE group_name = 'linux' 
_groups_sql() {
    echo "
    SELECT 
        JSON_OBJECT(
            group_name, 
            JSON_OBJECT(
                'hosts', 
                JSON_ARRAYAGG(host_name)
            )
        )
    FROM ansible_groups 
    LEFT JOIN ansible_hosts 
    ON ansible_groups.ID = ansible_hosts.ansible_group_id
    GROUP BY group_name;"
}

_group_vars_sql() {
    echo "
    SELECT 
       JSON_OBJECTAGG(
           ansible_var_name, 
           ansible_var_value
       )
    FROM ansible_groups 
    INNER JOIN ansible_group_vars 
    ON ansible_groups.ID = ansible_group_vars.ansible_group_id 
    WHERE group_name = '$1'
    GROUP BY group_name;"
}

_hosts_sql() {
    echo "
    SELECT host_name
    FROM ansible_hosts
    ;"
}

_host_vars_sql() {
    echo "
    SELECT 
        JSON_OBJECTAGG(
            ansible_var_name, 
            ansible_var_value
        ) 
    FROM ansible_hosts 
    INNER JOIN ansible_host_vars 
    ON ansible_hosts.ID = ansible_host_vars.ansible_host_id 
    WHERE HOST_NAME = '$1' 
    GROUP BY host_name;
"
}

IFS=$'\n'
for _GROUP_HOSTS in $(eval ${DB_CONN} -s -N -e \"$(_groups_sql)\"); do
    # echo "${_GROUP_HOSTS}"
    _JSON=$(echo "${_JSON}" | jq '. += '"${_GROUP_HOSTS}")
done

for _GROUP in $(echo "${_JSON}" | jq -r '. | keys | .[]'); do
    _GROUP_VARS=$(eval ${DB_CONN} -s -N -e \"$(_group_vars_sql ${_GROUP})\")
    if [[ -n ${_GROUP_VARS} ]]; then
        _JSON=$(echo "${_JSON}" | jq '.'"${_GROUP}"' |= (.vars='"${_GROUP_VARS}"')')
    fi
done

_JSON=$(echo "${_JSON}" | jq '. += (._meta.hostvars={})')

for _HOST in $(eval ${DB_CONN} -s -N -e \"$(_hosts_sql)\"); do
    _HOST_VARS=$(eval ${DB_CONN} -s -N -e \"$(_host_vars_sql ${_HOST})\")
    if [[ -n ${_HOST_VARS} ]]; then
        _JSON=$(echo "${_JSON}" | jq '._meta.hostvars |= (.'${_HOST}'='${_HOST_VARS}')')
    fi
done

echo "${_JSON}"
