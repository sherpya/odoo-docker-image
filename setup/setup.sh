#!/bin/sh
set -ex

curl -LsSf https://astral.sh/uv/install.sh | sh

REQS=""
for req in /odoo/addons/*/requirements.txt; do
    if [ -f ${req} ]; then
        echo "Adding requirements from ${req}"
        REQS="${REQS} -r ${req}"
    fi
done

for req in /setup/requirements.d/*.txt; do
    if [ -f ${req} ]; then
        echo "Adding requirements from ${req}"
        REQS="${REQS} -r ${req}"
    fi
done

$HOME/.cargo/bin/uv -n pip install \
    --system --break-system-packages \
    --override /setup/override.txt \
    -r requirements.txt \
    ${REQS} \
    psycopg2-binary
