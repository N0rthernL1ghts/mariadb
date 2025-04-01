#!/usr/bin/with-contenv bash
# shellcheck shell=bash

set -eo pipefail

# Attempt to replicate mysql_real_escape_string() from PHP
mysql_real_escape_string() {
    local str="${1:?}"

    # First escape backslashes (must be done first)
    str="${str//\\/\\\\}"

    # Escape control characters in order of ASCII values
    str="${str//$'\x00'/\\0}" # NUL
    str="${str//$'\x08'/\\b}" # Backspace
    str="${str//$'\x09'/\\t}" # Horizontal tab
    str="${str//$'\x0a'/\\n}" # Newline
    str="${str//$'\x0d'/\\r}" # Carriage return
    str="${str//$'\x1a'/\\Z}" # Substitute (Ctrl+Z)

    # Escape quotes and special characters
    str="${str//\'/\\\'}"
    str="${str//\"/\\\"}"

    printf '%s' "${str}"
}

execute_raw_query() {
    local query="${1:?}"

    if [ "${DEBUG_ENABLED:-0}" -eq 1 ]; then
        echo "Query: \"${query}\"" >&2
        mariadb --user root -ve "${query}"
        return
    fi

    mariadb --user root -e "${query}"
}

execute_query() {
    # shellcheck disable=SC2059
    execute_raw_query "$(printf "${1:?}" "${@:2}")"
}

execute_escaped_query() {
    # Use printf to populate the query with all the provided arguments
    local format="${1:?}" # Mandatory format string
    local escaped_args=()

    # Escape all arguments starting from the 2nd one
    for arg in "${@:2}"; do
        escaped_args+=("$(mysql_real_escape_string "${arg}")")
    done

    # shellcheck disable=SC2059
    execute_raw_query "$(printf "${format}" "${escaped_args[@]}")"
}

does_user_exist() {
    local username="${1:?Username is required}"
    local host="${2:-%}"

    execute_escaped_query "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE User = '%s' AND Host = '%s');" "${username}" "${host}" | grep -q '^1'
}

does_database_exist() {
    local database_name="${1:?Database name is required}"

    execute_escaped_query "SHOW DATABASES LIKE '%s';" "${database_name}" | grep -q "^${database_name}$"
}

create_user() {
    local username="${1:?Username is required}"
    local password="${2:?Password is required}"
    local host="${3:-%}"
    local create_user_db="${CREATE_USER_DB:-true}"

    execute_escaped_query "CREATE USER '%s'@'%s' IDENTIFIED BY '%s';" "${username}" "${host}" "${password}" || return

    if [ "${create_user_db}" = "true" ]; then
        create_database "${username}" "${username}"
    fi
}

user_with_password_exists() {
    local username="${1:?Username is required}"
    local password="${2:?Password is required}"
    local host="${3:-%}"

    execute_escaped_query "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE User = '%s' AND Host = '%s' AND Password = PASSWORD('%s'));" "${username}" "${host}" "${password}" | grep -q '^1'
}

create_database() {
    local database_name="${1:?Database name is required}"

    # shellcheck disable=SC2016
    execute_escaped_query 'CREATE DATABASE `%s`;' "${database_name}"

    local grant_to_user="${2:-}"
    if [ -n "${grant_to_user}" ]; then
        grant_privileges_on_database "${grant_to_user}" "${database_name}"
    fi
}

drop_database() {
    local database_name="${1:?Database name is required}"

    # shellcheck disable=SC2016
    execute_escaped_query 'DROP DATABASE `%s`;' "${database_name}"
}

grant_privileges_on_database() {
    local username="${1:?Username is required}"
    local database_name="${2:?Database name is required}"
    local host="${3:-%}"

    # shellcheck disable=SC2016
    execute_escaped_query "GRANT ALL PRIVILEGES ON \`%s\`.* TO '%s'@'%s';" "${database_name}" "${username}" "${host}"
}

is_mysql_running() {
    execute_raw_query 'SELECT 1;'
}

main() {
    local command="${1:-_empty_}"

    if [ ! -S "/run/mysqld/mysqld.sock" ]; then
        echo "Error: MySQL is not running"
        return 1
    fi

    case "${command}" in
    user-exists) does_user_exist "${@:2}" ;;
    user-create) create_user "${@:2}" ;;
    user-with-password-exists) user_with_password_exists "${@:2}" ;;
    db-exists) does_database_exist "${@:2}" ;;
    db-create) create_database "${@:2}" ;;
    db-drop) drop_database "${@:2}" ;;
    db-grant-privileges) grant_privileges_on_database "${@:2}" ;;
    flush-privileges | flush-privs) execute_query 'FLUSH PRIVILEGES;' ;;
    execute-escaped-query) execute_escaped_query "${@:2}" ;;
    healthcheck) is_mysql_running ;;
    *)
        echo "Unknown command: ${command}"
        echo "Usage: db-util <command> [args]"
        return 1
        ;;
    esac
}

main "${@}"
