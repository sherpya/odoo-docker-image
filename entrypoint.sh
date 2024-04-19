#!/bin/bash

set -e
umask 0077

if [ -t 1 -a "$(tput -T"$TERM" colors 2>/dev/null || echo 0)" -ge 8 ]; then
    RED='[01;31m'
    YELLOW='[01;33m'
    NC='[0m'
fi

if [ -z "${ODOO_DB_USER}" -o -z "${ODOO_DB_PASSWORD}" -o -z "${ODOO_DB_HOST}" ]; then
    echo -e "${RED}Missing db user, password or host!${NC}"
    exit 1;
fi

if [ ! -z "${ODOO_DATA_DIR}" ]; then
    echo "${YELLOW}Warning overriding odoo data_dir is not recommended!${NC}"
fi

if [ -z "${ODOO_ADMIN_PASSWD}" ]; then
    ODOO_ADMIN_PASSWD="$(tr -dc 'A-Za-z0-9!?%=' </dev/urandom | head -c 10)"
    echo "${YELLOW}Odoo admin password is unset! This temporary random password will used: ${RED}${ODOO_ADMIN_PASSWD}${NC}"
fi

ODOO_ADDONS_PATH="/odoo/source/addons,/odoo/source/odoo/addons,/mnt/extra-addons"
for dir in /odoo/addons/*; do
    if [ -d "${dir}" ]; then
        ODOO_ADDONS_PATH="${ODOO_ADDONS_PATH},${dir}"
    fi
done

ODOO_LIST_DB=${ODOO_LIST_DB:=True}
ODOO_DB_PORT=${ODOO_DB_PORT:=5432}
ODOO_WORKERS=${ODOO_WORKERS:=0}
ODOO_MAX_CRON_THREADS=${ODOO_MAX_CRON_THREADS:=1}
ODOO_DATA_DIR=${ODOO_DATA_DIR:=/odoo/data}
ODOO_PROXY_MODE=${ODOO_PROXY_MODE:=True}

echo "Generating Odoo configuration..."

(
echo '[options]'
for var in ${!ODOO_@}; do
    key=${var#ODOO_}
    key=${key,,}  # Convert to lowercase
    echo "${key} = ${!var}"
done
) > ~/.odoorc

echo "Waiting for Database to come up..."

sleep_time=1  # Initial sleep time in seconds
max_sleep_time=60  # Maximum sleep time to prevent too long delays

while true; do
    if  PGPASSWORD=${ODOO_DB_PASSWORD} psql -h ${ODOO_DB_HOST} -p ${ODOO_DB_PORT} -U ${ODOO_DB_USER} -d template1 -c "SELECT 1" > /dev/null 2>&1; then
        echo "Database is up and running"
        break;
    else
       echo "Unable to connect to the database. Retrying in $sleep_time second(s)..."
        sleep $sleep_time
        sleep_time=$((sleep_time * 2))  # Exponential back-off
        if [ $sleep_time -gt $max_sleep_time ]; then
            sleep_time=$max_sleep_time  # Cap the sleep time
        fi
    fi
done

exec "$@"
