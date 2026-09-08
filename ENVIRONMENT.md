# Environment Variables

These variables are intended for the Railway SuiteCRM service.

```env
PORT=8080
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_NAME=${{MySQL.MYSQLDATABASE}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
SITE_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
```

## Purpose

| Variable | Purpose |
|---|---|
| `PORT` | HTTP port used by Apache inside the container |
| `DB_HOST` | MySQL hostname from the Railway MySQL service |
| `DB_PORT` | MySQL port from the Railway MySQL service |
| `DB_NAME` | MySQL database name |
| `DB_USER` | MySQL username |
| `DB_PASSWORD` | MySQL password |
| `SITE_URL` | Public SuiteCRM URL |
