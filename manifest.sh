#!/bin/sh

(
for repo in odoo addons/*; do
    if [ -e ${repo}/.git ]; then
        name=$(basename ${repo})
        branch=$(GIT_DIR="${repo}/.git" git branch --show-current)
        hash=$(GIT_DIR="${repo}/.git" git rev-parse HEAD)
        echo "${name}:${branch}:${hash}"
    fi
done
) > manifest.txt
