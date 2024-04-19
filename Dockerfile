FROM debian:bookworm-slim

LABEL org.opencontainers.image.authors="sherpya@gmail.com"

ENV LANG C.UTF-8

ARG TARGETARCH
ARG WKHTMLTOPDF_DISTRO=bookworm
ARG WKHTMLTOPDF_VERSION=0.12.6.1-3

# Upgrade packages & Dependencies
# fonts-noto-cjk
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl ca-certificates postgresql-client \
    libjpeg62-turbo libpng16-16 libxrender1 libfontconfig1 \
    python3-ldap python3-libsass python3-psutil \
    && apt-get clean

# Install wkhtmltopdf
RUN \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    case ${TARGETARCH} in \
        "amd64") WKHTMLTOPDF_SHA=e9f95436298c77cc9406bd4bbd242f4771d0a4b2 ;; \
        "arm64") WKHTMLTOPDF_SHA=77bc06be5e543510140e6728e11b7c22504080d4 ;; \
        *) { echo "Unsupported architecture"; exit 1; } ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.${WKHTMLTOPDF_DISTRO}_${TARGETARCH}.deb \
    && echo "${WKHTMLTOPDF_SHA} wkhtmltox.deb" | sha1sum -c - \
    && dpkg --fsys-tarfile wkhtmltox.deb | tar xOf - ./usr/local/bin/wkhtmltopdf > /usr/local/bin/wkhtmltopdf \
    && chmod 755 /usr/local/bin/wkhtmltopdf \
    && rm -fr /var/lib/apt/lists/* wkhtmltox.deb

ENV PYTHONDONTWRITEBYTECODE 1

RUN useradd -ms /bin/bash odoo

WORKDIR /odoo/source

# Copy odoo
COPY --chown=odoo:odoo odoo /odoo/source

# Copy addons
COPY --chown=odoo:odoo addons /odoo/addons/

# Install dependencies
COPY setup /setup
RUN sh /setup/setup.sh && rm -fr /setup

# Setup data dir mount point
RUN install -d -o odoo -g odoo /odoo/data
COPY ./entrypoint.sh /

USER odoo

VOLUME ["/odoo/data", "/mnt/extra-addons"]

EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./odoo-bin"]
