# Railway Template Configuration

Use this file as the checklist when composing the public Railway template.

## SuiteCRM service

**Source:** GitHub repository containing this folder

**Build:** Dockerfile

**Port:** `8080`

**Healthcheck Path:** `/index.php`

**Volume mount:**

```text
/var/www/html
```

## SuiteCRM variables

```env
PORT=8080
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_NAME=${{MySQL.MYSQLDATABASE}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
SITE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
```

Mark database reference variables as required only when necessary for the template UI. Do not expose database passwords in README examples beyond Railway reference syntax.

## MySQL service

**Image:**

```text
mysql:8.4
```

**Volume mount:**

```text
/var/lib/mysql
```

## Recommended template description

```text
Open-source CRM for sales, marketing, customer service, and automation
```

## Template checklist

- [ ] SuiteCRM service builds successfully from GitHub
- [ ] MySQL 8.4 service starts successfully
- [ ] `/var/www/html` volume is attached to SuiteCRM
- [ ] `/var/lib/mysql` volume is attached to MySQL
- [ ] Public domain is generated
- [ ] Healthcheck uses `/index.php`
- [ ] Database reference variables resolve correctly
- [ ] SuiteCRM installer loads on a fresh deployment
- [ ] Administrator account can be created
- [ ] Login works after restart
- [ ] Data survives redeploy
- [ ] `cron.php` executes every minute
- [ ] API endpoints work
- [ ] File uploads work
- [ ] Customization survives redeploy
- [ ] Backup/restore tested
