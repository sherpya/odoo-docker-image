FROM debian:bookworm-slim

LABEL org.opencontainers.image.authors="sherpya@gmail.com"

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

ENV LANG C.UTF-8

ARG TARGETARCH

# Upgrade packages & Dependencies
# fonts-noto-cjk
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl ca-certificates \
    libjpeg62-turbo libpng16-16 libxrender1 libfontconfig1 \
    python3-ldap python3-libsass python3-psutil \
    && apt-get clean

# Install required stuff
RUN \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    case ${TARGETARCH} in \
        "amd64") WKHTMLTOPDF_SHA=9df8dd7b1e99782f1cfa19aca665969bbd9cc159 LIBSSL1_SHA=143f4bea9121c4f40ae3891fc1920e75d71fea83 ;; \
        "arm64") WKHTMLTOPDF_SHA=58c84db46b11ba0e14abb77a32324b1c257f1f22 LIBSSL1_SHA=2e5371318577654a1e18cfae8a96f9a0cb3f26f2 ;; \
        *) { echo "Unsupported architecture"; exit 1; } ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bullseye_${TARGETARCH}.deb \
    && echo "${WKHTMLTOPDF_SHA} wkhtmltox.deb" | sha1sum -c - \
    && dpkg --fsys-tarfile wkhtmltox.deb | tar xOf - ./usr/local/bin/wkhtmltopdf > /usr/local/bin/wkhtmltopdf \
    && chmod 755 /usr/local/bin/wkhtmltopdf \
    && curl -o libssl1.deb -sSL http://security.debian.org/pool/main/o/openssl/libssl1.1_1.1.1n-0+deb10u6_${TARGETARCH}.deb \
    && echo "${LIBSSL1_SHA} libssl1.deb" | sha1sum -c - \
    && dpkg -i ./libssl1.deb \
    && rm -fr /var/lib/apt/lists/* wkhtmltox.deb libssl1.deb

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN useradd -ms /bin/bash odoo

WORKDIR /odoo/app
COPY --chown=odoo:odoo ./odoo ./
COPY --chown=odoo:odoo ./override.txt ./

RUN install -d -o odoo -g odoo /odoo/data /odoo/addons

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN $HOME/.cargo/bin/uv -n pip install --system --break-system-packages --override override.txt -r requirements.txt psycopg2-binary

COPY ./entrypoint.sh /

USER odoo

VOLUME ["/odoo/data", "/mnt/extra-addons"]

EXPOSE 8069 8072

ENTRYPOINT ["/entrypoint.sh"]
CMD ["./odoo-bin"]
