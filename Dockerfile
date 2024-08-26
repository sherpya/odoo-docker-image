ARG DISTRO=bookworm
FROM debian:${DISTRO}-slim

LABEL org.opencontainers.image.authors="sherpya@gmail.com"
LABEL org.opencontainers.image.title="Odoo Docker Image"
LABEL org.opencontainers.image.description="Docker image for Odoo based on latest Debian with minimal packages."

ENV LANG C.UTF-8

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Upgrade packages & Dependencies
# add fonts-noto-cjk for CJK support
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    procps netcat-traditional iputils-ping htop \
    curl ca-certificates postgresql-client \
    libjpeg62-turbo libpng16-16 libxrender1 libfontconfig1 \
    python3-pip python3-ldap python3-libsass python3-psutil \
    && apt-get clean && rm -fr /var/lib/apt/lists/*

ARG TARGETARCH

ARG WKHTMLTOPDF_VERSION=0.12.6.1-3

ARG WKHTMLTOPDF_SHA_amd64_bookworm=e9f95436298c77cc9406bd4bbd242f4771d0a4b2
ARG WKHTMLTOPDF_SHA_arm64_bookworm=77bc06be5e543510140e6728e11b7c22504080d4

ARG WKHTMLTOPDF_SHA_amd64_bullseye=9df8dd7b1e99782f1cfa19aca665969bbd9cc159
ARG WKHTMLTOPDF_SHA_arm64_bullseye=58c84db46b11ba0e14abb77a32324b1c257f1f22

# Install wkhtmltopdf
RUN \
    if [ -z "${TARGETARCH:=}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    DISTRO=$(source /etc/os-release && echo $VERSION_CODENAME) \
    && eval "WKHTMLTOPDF_SHA=\$WKHTMLTOPDF_SHA_${TARGETARCH}_${DISTRO}" \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox_${WKHTMLTOPDF_VERSION}.${DISTRO}_${TARGETARCH}.deb \
    && echo "${WKHTMLTOPDF_SHA} wkhtmltox.deb" | sha1sum -c - \
    && dpkg --fsys-tarfile wkhtmltox.deb | tar xOf - ./usr/local/bin/wkhtmltopdf > /usr/local/bin/wkhtmltopdf \
    && chmod 755 /usr/local/bin/wkhtmltopdf \
    && rm -fr /var/lib/apt/lists/* wkhtmltox.deb

ENV PYTHONDONTWRITEBYTECODE 1

RUN useradd -ms /bin/bash odoo

WORKDIR /odoo/source

# Copy manifest if present
COPY --chown=odoo:odoo manifest.tx[t] /odoo/

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
