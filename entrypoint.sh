#!/bin/bash

set -e
umask 0077

if [ -z "${ODOO_DB_USER}" -o -z "${ODOO_DB_PASSWORD}" -o -z "${ODOO_DB_HOST}" ]; then
    echo "Missing db user, password or host"
    exit 1;
fi

ODOO_ADDONS_PATH="/odoo/app/addons,/odoo/app/odoo/addons,/mnt/extra-addons"
for dir in /odoo/addons/*; do
    if [ -d ${dir} ]; then
        ODOO_ADDONS_PATH="${ODOO_ADDONS_PATH},${dir}"
    fi
done

ODOO_LIST_DB=${ODOO_LIST_DB:=True}
ODOO_ADMIN_PASSWD=${ODOO_ADMIN_PASSWD:=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 10)}
ODOO_WORKERS=${ODOO_WORKERS:=0}
ODOO_MAX_CRON_THREADS=${ODOO_MAX_CRON_THREADS:=1}

(
cat << EOF
[options]
data_dir = /odoo/data
proxy_mode = True
EOF

for var in ${!ODOO_@}; do
    key=$(echo $var | sed 's/^ODOO_//' | tr '[:upper:]' '[:lower:]')
    echo "${key} = ${!var}"
done
) > ~/.odoorc

exec "$@"
