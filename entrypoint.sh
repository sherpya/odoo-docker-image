#!/bin/bash

set -e
umask 0077

if [ $(tput -T $TERM colors) != -1 ]; then
    RED='[01;31m'
    YELLOW='[01;33m'
    NC='[0m'
fi

if [ -z "${ODOO_DB_USER}" -o -z "${ODOO_DB_PASSWORD}" -o -z "${ODOO_DB_HOST}" ]; then
    echo -e "${RED}Missing db user, password or host!${NC}"
    exit 1;
fi

if [ ! -z ${ODOO_DATA_DIR} ]; then
    echo "${YELLOW}Warning overriding odoo data_dir is not recommended!${NC}"
fi

if [ -z ${ODOO_ADMIN_PASSWD} ]; then
    ODOO_ADMIN_PASSWD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 10)
    echo "${YELLOW}Odoo admin password is unset! A temporary random one will used: ${RED}${ODOO_ADMIN_PASSWD}${NC}"
fi

ODOO_ADDONS_PATH="/odoo/source/addons,/odoo/source/odoo/addons,/mnt/extra-addons"
for dir in /odoo/addons/*; do
    if [ -d ${dir} ]; then
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
    key=$(echo $var | sed 's/^ODOO_//' | tr '[:upper:]' '[:lower:]')
    echo "${key} = ${!var}"
done
) > ~/.odoorc

echo "Waiting for Database to come up..."

while true; do
    if PGPASSWORD=${ODOO_DB_PASSWORD} psql -h $ODOO_DB_HOST -p $ODOO_DB_PORT -U $ODOO_DB_USER -d template1 -c "SELECT 1" > /dev/null; then
        echo "Database is up and running"
        break
    else
        echo "Unable to connect to the database. Retrying in 1 second..."
        sleep 1
    fi
done

exec "$@"
