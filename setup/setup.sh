#!/bin/sh
set -e

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Collect requirements
REQS=""
for req in /odoo/addons/*/requirements.txt; do
    if [ -f ${req} ]; then
        echo "Adding requirements from ${req}"
        REQS="${REQS} -r ${req}"
    fi
done

# Collect user added requirements
for req in /setup/requirements.d/*.txt; do
    if [ -f ${req} ]; then
        echo "Adding requirements from ${req}"
        REQS="${REQS} -r ${req}"
    fi
done

# Install
$HOME/.cargo/bin/uv -n pip install \
    --system --break-system-packages \
    --override /setup/override.txt \
    -r requirements.txt \
    ${REQS} \
    psycopg2-binary

# Cleanup
rm -f /tmp/*.lock /var/log/apt/* /var/log/*.log /var/cache/debconf/*-old
rm -f /etc/passwd- /etc/shadow- /etc/group- /etc/gshadow-
rm -fr /usr/local/share/man
