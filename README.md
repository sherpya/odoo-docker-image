# Optimized Odoo Docker Image

This project provides a Dockerfile and supporting scripts for creating customized and optimized
Odoo images based on `debian:bookworm-slim`. It's designed to streamline the deployment
of Odoo and includes automatic download of the correct version of `wkhtmltopdf` for PDF rendering.
The image supports both `amd64` and `arm64` platforms.

## Features

- **Customized Odoo Deployment**: Build Odoo images that are tailored to your specific needs.
- **Multi-Platform Support**: Compatible with both AMD64 and ARM64 architectures.
- **Automatic Configuration**: Automatically generates configuration and installs necessary requirements for added addons.

## Prerequisites

Before you can use this Docker image, ensure you have Docker installed on your machine.
If you plan to use Docker Compose, that should also be installed.

## Getting Started

1. **Clone Odoo Repository**: First, you need to clone the Odoo repository into a local directory
named `odoo`. Ensure you maintain the branch corresponding to the Odoo version you want to use. For example,
to clone Odoo version 16.0:

   ```bash
   git clone -b 16.0 --depth 1 https://github.com/odoo/odoo.git odoo
   ```

2. **Clone Addon Repositories**: Next, clone the repositories of the addons you want to include in the directory `addons/`,
maintaining the branch consistency. For each addon you add, the build process automatically creates the appropriate
configuration and installs the requirements from the addon's `requirements.txt`.
For example, to add the `partner-contact` addon for Odoo version 16.0:

   ```bash
   git clone -b 16.0 https://github.com/OCA/partner-contact.git addons/partner-contact
   ```

3. **Add Custom Requirements**: You can also add your own custom requirement files in
the `setup/requirements.d/` directory. For example, to include additional dependencies for PDF handling,
you might add a file named `pdfminer.txt` at `setup/requirements.d/pdfminer.txt`.

## Environment Configuration

To configure the image, pass environment variables with the prefix `ODOO_` and the Odoo option name in uppercase.
For example, `ODOO_DB_USER` and `ODOO_DB_PASSWORD`.
If `ODOO_ADMIN_PASSWD` is not specified, a temporary password will be generated at each startup, indicated by the following output:

```plaintext
Odoo admin password is unset! This temporary random password will be used: sDBY0X62Fw
```

## Docker Compose

An example `docker-compose.yaml` file is included in the repository to facilitate testing.
To build and run the containers, execute:

```bash
docker compose up --build
```

## Conclusion

This Docker image makes it easy to deploy a fully functional and optimized Odoo instance tailored to your needs,
supporting a wide range of configurations and addons. Happy Odooing!
