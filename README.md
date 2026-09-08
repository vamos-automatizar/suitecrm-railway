# SuiteCRM 7.15.2 for Railway

Self-hosted SuiteCRM 7.15.2 deployment prepared for Railway using the official SuiteCRM source release, PHP 8.4, Apache 2.4, and MySQL 8.4.

## Architecture

- **SuiteCRM:** 7.15.2
- **PHP:** 8.4
- **Web server:** Apache 2.4
- **Database:** MySQL 8.4
- **Container port:** 8080
- **Scheduler:** SuiteCRM `cron.php` executed every minute
- **Persistent application volume:** `/var/www/html`
- **Persistent database volume:** `/var/lib/mysql`

SuiteCRM 7.15.x officially supports PHP 8.1–8.4, Apache 2.4, and MySQL 8.0/8.4. SuiteCRM 7.15.2 is the current 7.x release. See the official compatibility matrix and release notes for details.

## Deploy on Railway

Create a Railway project from this repository and add:

1. A **SuiteCRM** service from this GitHub repository.
2. A **MySQL** service using `mysql:8.4`.
3. A persistent volume for SuiteCRM mounted at `/var/www/html`.
4. A persistent volume for MySQL mounted at `/var/lib/mysql`.
5. A public domain for the SuiteCRM service.

Railway reference variables should be used for the database connection so users do not have to copy credentials manually.

## Recommended Railway Variables

Set the following variables on the SuiteCRM service:

```env
PORT=8080
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_NAME=${{MySQL.MYSQLDATABASE}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
SITE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
```

The current Docker image uses the official SuiteCRM web installer for the initial database/site configuration. The `DB_*` and `SITE_URL` variables are provided as deployment references and should be entered into the installer when requested.

## First Access

After the services are running:

1. Open the Railway public URL.
2. The SuiteCRM installation wizard should appear if the persistent volume is empty.
3. Accept the AGPL license.
4. Complete the system requirements check.
5. Configure the database using the Railway-provided MySQL reference values.
6. Set your SuiteCRM administrator username and password.
7. Set the site URL to the Railway public URL.
8. Finish the installation and sign in.

### Database values

Use these values during the installer:

| SuiteCRM field | Railway value |
|---|---|
| Database Type | MySQL |
| Host Name | `${{MySQL.MYSQLHOST}}` |
| Database Name | `${{MySQL.MYSQLDATABASE}}` |
| User Name | `${{MySQL.MYSQLUSER}}` |
| Password | `${{MySQL.MYSQLPASSWORD}}` |
| Port | `${{MySQL.MYSQLPORT}}` |

## Scheduled Tasks

SuiteCRM requires its scheduler to run for features such as **Workflows, Emails, and Schedulers**.

This container automatically executes:

```bash
php -f cron.php
```

every minute in the background, matching the cadence recommended in the official SuiteCRM installation documentation.

## Persistence

### SuiteCRM

Mount the Railway volume at:

```text
/var/www/html
```

This preserves the installed SuiteCRM instance, configuration, customizations, uploads, cache, and application data across container redeployments.

### MySQL

Mount the database volume at:

```text
/var/lib/mysql
```

Never remove the MySQL volume unless you intentionally want to destroy the database.

## Updating SuiteCRM

The application version is intentionally pinned to **7.15.2**. Avoid using `latest` for a public Railway template.

Before upgrading a deployed instance:

1. Back up the MySQL database.
2. Back up the SuiteCRM volume.
3. Review the official SuiteCRM upgrade guide.
4. Test the target release separately.
5. Upgrade the application only after confirming compatibility.

The Dockerfile downloads the SuiteCRM source from the official GitHub release tag rather than relying on a third-party SuiteCRM container image.

## Requirements

SuiteCRM 7.15.x officially supports:

- PHP 8.1, 8.2, 8.3, 8.4
- Apache 2.4
- MySQL 8.0 and 8.4

This image uses PHP 8.4 and Apache 2.4.

SuiteCRM 7.15.0 also raised the minimum PHP version to 8.1 and added PHP 8.4 support. PHP 8.4 no longer bundles the IMAP extension, so this image installs IMAP explicitly.

## Security Notes

- Use a strong SuiteCRM administrator password.
- Do not commit `.env` files or database credentials.
- Keep the Railway MySQL volume persistent.
- Keep the SuiteCRM version pinned and update deliberately.
- Review SuiteCRM security releases before upgrading.

## Official Resources

- [SuiteCRM](https://suitecrm.com/)
- [SuiteCRM GitHub](https://github.com/SuiteCRM/SuiteCRM)
- [SuiteCRM 7 Installation Guide](https://docs.suitecrm.com/admin/installation-guide/downloading-installing/)
- [SuiteCRM 7 Compatibility Matrix](https://docs.suitecrm.com/admin/compatibility-matrix/)
- [SuiteCRM 7.15.x Release Notes](https://docs.suitecrm.com/admin/releases/7.15.x/)
- [Railway Templates](https://docs.railway.com/templates/create)

## License

SuiteCRM source code is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

This repository contains deployment/build files intended to build a Railway-compatible container from the official SuiteCRM source release.
