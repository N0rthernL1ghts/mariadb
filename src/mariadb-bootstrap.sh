#!/usr/bin/with-contenv bash
# shellcheck shell=bash

set -o pipefail

# Generate a random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-16
}

# Trim input string.
# Source: https://stackoverflow.com/a/3352015
trim() {
    local var="$*"

    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"

    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"

    printf '%s' "${var}"
}

# Create a user function
create_user() {
    local user="${1:?User required}"
    local password="${2:-}"

    printf "Creating user '%s'\n" "${user}"

    if db-util user-exists "${user}"; then
        printf "User '%s' already exists\n" "${user}" >&2

        return 1
    fi

    if [ -z "${password}" ]; then
        local password_file="/config/.${user}.password"
        local user_password_env_var="MARIADB_USER_${user^^}_PASSWORD"
        local user_password_env_value="${!user_password_env_var}"

        if [ -n "${user_password_env_value}" ] && [ "${#user_password_env_value}" -gt "1" ]; then
            password="$(trim "${user_password_env_value}")"
            printf "  Password retrieved from environment %s\n" "${user_password_env_var}"
        elif [ -f "${password_file}" ] && [ -s "${password_file}" ]; then
            password=$(<"${password_file}")
            password=$(trim "${password}")
            printf "  Password retrieved from %s\n" "${password_file}"
        else
            password=$(generate_password)
            printf "  Random password has been generated and stored in %s\n" "${password_file}"
        fi
    fi

    if db-util user-create "${user}" "${password}"; then
        printf "User '%s' created with password '%s'\n" "${user}" "${password}"

        return 0
    fi

    printf "Error: Failed to create user '%s'\n" "${user}" >&2
    return 1
}

# Create a database function
create_database() {
    local database="${1:?Database required}"

    printf "Creating database '%s'\n" "${database}"

    if db-util db-exists "${database}"; then
        printf "Database '%s' already exists\n" "${database}"
        return 0
    fi

    if db-util db-create "${database}"; then
        printf "Database '%s' created\n" "${database}"
        return 0
    fi

    printf "Error: Failed to create database '%s'\n" "${database}" >&2
    return 1
}

# Function to create batch users
create_batch_users() {
    local users

    users=$(echo "${1:?Users required}" | tr "|" "\n")

    for user in ${users}; do
        IFS=':' read -r username password <<<"${user}"

        if [ -n "${pasword}" ]; then
            local password_var_name="MARIADB_USER_${username^^}_PASSWORD"
            printf "Warning: Setting password by %s:password syntax is deprecated. Please use environment variable '%s' instead\n" "${username}" "${password_var_name}" >&2
        fi

        create_user "${username}" "${password:-}"
        sleep 0.1
    done
}

# Function to create batch databases
create_batch_databases() {
    local databases

    databases=$(echo "${1:?Databases required}" | tr "," "\n")

    for database in ${databases}; do
        IFS=':' read -r database_name assigned_user <<<"${database}"

        if create_database "${database_name}"; then
            if [ -n "${assigned_user}" ]; then
                printf "Assigning user '%s' to database '%s'..." "${assigned_user}" "${database_name}"

                db-util db-grant-privileges "${assigned_user}" "${database_name}"
            elif [ -n "${MARIADB_USERNAME}" ]; then
                printf "Assigning user '%s' to database '%s'..." "${MARIADB_USERNAME}" "${database_name}"

                db-util db-grant-privileges "${MARIADB_USERNAME}" "${database_name}"
            fi
        fi
        sleep 0.1
    done
}

function check_hash_update() {
    local input_string="${1:?Input string required}"
    local hash_file="${2:?Hash file required}"
    local calculated_hash

    # Calculate SHA256 hash of the input string
    calculated_hash=$(echo -n "${input_string}" | sha256sum | awk '{print $1}')

    if [ ! -f "${hash_file}" ]; then
        printf "Warning: Hash file '%s' doesn't exist. Creating a new one with hash '%s'.\n" "${hash_file}" "${calculated_hash}" >&2

        # Create a new hash file with the new hash and return 1 to indicate that the hash has changed (since there was no previous hash)
        printf "%s" "${calculated_hash}" >"${hash_file}"
        return 1
    fi

    # Compare the new hash with the stored hash
    if [ "${calculated_hash}" == "$(cat "${hash_file}")" ]; then
        # Hashes are the same, meaning there is nothing to update
        return 0
    fi

    # Update the hash file with the new hash and return 1 to indicate that the hash has changed
    printf "%s" "${calculated_hash}" >"${hash_file}"
    return 1
}

# Main function
main() {
    printf "[MariaDB Runtime Bootstrap v2.1]\n"

    if [ -n "${MARIADB_USERNAME}" ]; then
        printf "Warning: MARIADB_USERNAME is deprecated. Please use MARIADB_INIT_USERS instead\n" >&2

        local username_entry="${MARIADB_USERNAME}:${MARIADB_PASSWORD}"
        if [ -n "${MARIADB_INIT_USERS}" ]; then
            MARIADB_INIT_USERS="${MARIADB_INIT_USERS}|${username_entry}"
        else
            MARIADB_INIT_USERS="${username_entry}"
        fi
    fi

    if [ -n "${MARIADB_DATABASE}" ]; then
        printf "Warning: MARIADB_DATABASE is deprecated. Please use MARIADB_INIT_DATABASES instead\n" >&2

        if [ -n "${MARIADB_INIT_DATABASES}" ]; then
            MARIADB_INIT_DATABASES="${MARIADB_INIT_DATABASES},${MARIADB_DATABASE}"
        else
            MARIADB_INIT_DATABASES="${MARIADB_DATABASE}"
        fi
    fi

    # This equals to ~5 seconds considering the sleep interval of 0.5 seconds
    local wait_limit=10

    until db-util healthcheck >/dev/null 2>&1; do
        if [ "${wait_limit}" -le 0 ]; then
            printf "Error: MariaDB failed to start\n" >&2
            return 1
        fi

        printf "Waiting for MariaDB to become ready...\n"
        sleep 0.5

        ((wait_limit--))
    done

    printf "Calculating MARIADB_INIT_USERS and MARIADB_INIT_DATABASES hashes...\n"

    if check_hash_update "${MARIADB_INIT_USERS}" "/config/.mariadb_init_users.hash"; then
        printf "MARIADB_INIT_USERS unchanged. Skipping users initialization.\n"
        MARIADB_INIT_USERS=""
    fi

    if check_hash_update "${MARIADB_INIT_DATABASES}" "/config/.mariadb_init_databases.hash"; then
        printf "MARIADB_INIT_DATABASES unchanged. Skipping databases initialization.\n"
        MARIADB_INIT_DATABASES=""
    fi

    printf "MariaDB ready. Proceeding with initialization\n"

    if [ -n "${MARIADB_INIT_USERS}" ]; then
        printf "Initializing users...\n"

        create_batch_users "${MARIADB_INIT_USERS}"
        db-util flush-privileges
    fi

    if [ -n "${MARIADB_INIT_DATABASES}" ]; then
        printf "Initializing databases...\n"

        create_batch_databases "${MARIADB_INIT_DATABASES}"
    fi
}

main "$@"
