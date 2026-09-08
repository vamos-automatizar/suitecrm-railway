# SuiteCRM 7.15.2 for Railway

Deploy **SuiteCRM 7.15.2** on Railway using the official SuiteCRM source release, PHP 8.4, Apache 2.4, MySQL 8.4, persistent storage, and an automated scheduler.

SuiteCRM is an open-source CRM platform for sales, marketing, customer service, reporting, workflow automation, and customer relationship management.

## About Hosting

This repository provides a Railway-ready deployment of SuiteCRM 7.15.2 built from the official SuiteCRM source release.

The application runs on PHP 8.4 and Apache 2.4 and connects to a MySQL 8.4 service through Railway private networking.

Persistent storage is used for the SuiteCRM application and database so that configuration, uploaded files, customizations, and CRM data survive container restarts and redeployments.

The deployment also includes an automated background scheduler that runs SuiteCRM's `cron.php` every minute.

## Architecture

- **SuiteCRM:** 7.15.2
- **PHP:** 8.4
- **Web server:** Apache 2.4
- **Database:** MySQL 8.4
- **Container port:** 8080
- **Scheduler:** SuiteCRM `cron.php` every minute
- **SuiteCRM volume:** `/var/www/html`
- **MySQL volume:** `/var/lib/mysql`

SuiteCRM 7.15.x officially supports PHP 8.1–8.4, Apache 2.4, and MySQL 8.0/8.4.

## Common Use Cases

- **Sales CRM** — Manage leads, contacts, accounts, opportunities, quotes, and contracts.
- **Marketing Automation** — Run campaigns, manage target lists, and track marketing activities.
- **Customer Service** — Manage cases, activities, support requests, and customer history.
- **Workflow Automation** — Automate CRM processes, notifications, assignments, and updates.
- **Business Integrations** — Connect SuiteCRM with APIs, webhooks, n8n, Activepieces, and other automation platforms.

## Dependencies for SuiteCRM Hosting

This deployment uses the following supporting services and components.

### Deployment Dependencies

- PHP 8.4
- Apache 2.4
- MySQL 8.4
- Railway persistent volumes
- SuiteCRM scheduler (`cron.php`)

### Railway Services

The Railway project should contain:

1. A **SuiteCRM** service using this GitHub repository.
2. A **MySQL** service.
3. A persistent Volume attached to SuiteCRM at `/var/www/html`.
4. A persistent Volume attached to MySQL at `/var/lib/mysql`.
5. Public HTTP networking for the SuiteCRM service.

Railway reference variables allow the SuiteCRM service to use the MySQL service's connection information without hardcoding database credentials.

## Railway Variables

Set the following variables on the **SuiteCRM service**:

```env
PORT=8080

DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_NAME=${{MySQL.MYSQLDATABASE}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}

SITE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
```

These variables provide the database connection values that should be used during the SuiteCRM web installation.

> **Important:** These variables do not automatically complete the SuiteCRM web installer. During the first access, you must manually enter their resolved values in the SuiteCRM installation wizard.

Railway supports reference variables using the `${{SERVICE_NAME.VARIABLE_NAME}}` syntax.

## First Access

After deploying the services:

1. Wait for the SuiteCRM and MySQL services to start.
2. Open the public URL of the **SuiteCRM service**.
3. SuiteCRM will display the web installation wizard on the first installation.
4. Open the **Variables** tab of the **SuiteCRM service** in Railway.
5. Use the configured database variable values when completing the installer.
6. Configure the SuiteCRM administrator account.
7. Complete the installation.
8. Sign in with the administrator credentials you created.

### Database Configuration

In the SuiteCRM installer, select **MySQL** and enter the values from the **SuiteCRM service Variables**.

| SuiteCRM field | SuiteCRM service variable |
|---|---|
| Database Type | MySQL |
| Host Name | `DB_HOST` |
| Database Name | `DB_NAME` |
| User Name | `DB_USER` |
| Password | `DB_PASSWORD` |
| Port | `DB_PORT` |

> **Important:** Copy the actual values displayed in the **Variables** section of the **SuiteCRM service**. Do not enter the literal `${{...}}` expressions into the SuiteCRM installer.

### Identify Administration User

In the **Site Configuration** section, configure the initial SuiteCRM administrator:

- **SuiteCRM Application Admin Name** — Your administrator username.
- **SuiteCRM Admin User Password** — A strong administrator password.
- **Re-enter SuiteCRM Admin User Password** — Confirm the password.
- **URL of SuiteCRM Instance** — Your public Railway SuiteCRM URL.
- **Email Address** — Your administrator email address.

The administrator account created during installation will be used to access the SuiteCRM administration interface.

### Installation Checklist

Before completing the installer, make sure:

- Database values were copied from the **SuiteCRM service Variables**.
- MySQL host, database name, username, and password are correct.
- The administrator username and password are defined.
- The public Railway URL is configured as the SuiteCRM instance URL.
- A valid administrator email address is provided.

> **Important:** The Railway deployment does **not** automatically complete the SuiteCRM web installer. Database and administrator settings must be configured manually during the first access.

## Scheduled Tasks

SuiteCRM relies on scheduled tasks for functionality such as **Workflows, Emails, and Schedulers**.

This deployment automatically runs:

```bash
php -f cron.php
```

every minute in the background using the `www-data` user.

This follows the standard SuiteCRM approach of executing `cron.php` every minute.

## Persistence

### SuiteCRM

The SuiteCRM service uses a persistent Railway Volume mounted at:

```text
/var/www/html
```

This preserves the installed application, configuration, customizations, uploads, cache, and other application data across redeployments.

### MySQL

The MySQL service should use a persistent Volume mounted at:

```text
/var/lib/mysql
```

This preserves the CRM database across container restarts and redeployments.

> **Warning:** Removing the MySQL volume can permanently destroy your SuiteCRM database.

## Updating SuiteCRM

The application version is intentionally pinned to **7.15.2** rather than using `latest`.

This provides predictable builds and helps avoid unexpected changes in a public Railway template.

Before upgrading an existing installation:

1. Back up the MySQL database.
2. Back up the SuiteCRM Volume.
3. Review the official SuiteCRM upgrade documentation.
4. Test the target version separately.
5. Upgrade only after confirming compatibility.

The Dockerfile downloads the SuiteCRM source from the official GitHub release tag instead of depending on a third-party SuiteCRM container image.

## Requirements

SuiteCRM 7.15.x officially supports:

- **PHP:** 8.1, 8.2, 8.3, 8.4
- **Apache:** 2.4
- **MySQL:** 8.0, 8.4

This deployment uses:

- **PHP 8.4**
- **Apache 2.4**
- **MySQL 8.4**

SuiteCRM 7.15 introduced PHP 8.4 support. Because PHP 8.4 no longer bundles the IMAP extension, this image installs the required IMAP extension explicitly.

## Why Deploy SuiteCRM on Railway?

Railway provides a straightforward way to deploy the complete SuiteCRM stack without manually configuring a traditional server.

With this template, you can run SuiteCRM together with MySQL, persistent storage, private service-to-service networking, and scheduled background tasks.

This makes Railway suitable for self-hosted CRM projects that need flexibility, automation, customization, and control over their deployment environment.

## Security Notes

- Use a strong SuiteCRM administrator password.
- Never commit database passwords or other secrets to Git.
- Keep database and application volumes persistent.
- Keep SuiteCRM pinned to a specific release.
- Review official SuiteCRM security releases before upgrading.
- Do not expose the MySQL service publicly unless external database access is explicitly required.

## Source and Build

The Docker image is built from the official SuiteCRM source repository and release tag:

```text
https://github.com/SuiteCRM/SuiteCRM
```

The application version is controlled in the Dockerfile using:

```dockerfile
ARG SUITECRM_VERSION=7.15.2
```

This keeps the deployment reproducible and avoids relying on third-party SuiteCRM images.

## Official Resources

- [SuiteCRM](https://suitecrm.com/)
- [SuiteCRM GitHub](https://github.com/SuiteCRM/SuiteCRM)
- [SuiteCRM 7 Installation Guide](https://docs.suitecrm.com/admin/installation-guide/downloading-installing/)
- [SuiteCRM Compatibility Matrix](https://docs.suitecrm.com/admin/compatibility-matrix/)
- [SuiteCRM 7.15.x Release Notes](https://docs.suitecrm.com/admin/releases/7.15.x/)
- [Railway Templates](https://docs.railway.com/templates/create)
- [Railway Variables](https://docs.railway.com/variables)
- [Railway Volumes](https://docs.railway.com/volumes)

## License

SuiteCRM is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

This repository contains deployment and build configuration intended to create a Railway-compatible SuiteCRM environment from the official SuiteCRM source release.
