#!/usr/bin/env bash

set -Eeuo pipefail

APP_DIR="/var/www/html"
SEED_DIR="/opt/suitecrm"

echo "=========================================="
echo "SUITECRM ENTRYPOINT V6"
echo "BUILD SOURCE: vamos-automatizar/suitecrm-railway"
echo "DATE: 2026-09-08"
echo "=========================================="

echo "[suitecrm] Entrypoint started."

# ------------------------------------------------------------
# 1. FORCE APACHE PREFORK MPM
# ------------------------------------------------------------

echo "[suitecrm] Cleaning Apache MPM configuration..."

# Remove every enabled MPM module.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# Disable possible MPM modules registered by a2enmod.
a2dismod mpm_event 2>/dev/null || true
a2dismod mpm_worker 2>/dev/null || true
a2dismod mpm_prefork 2>/dev/null || true

# Remove them again to guarantee that no MPM is left enabled.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# Enable ONLY prefork.
a2enmod mpm_prefork

echo "[suitecrm] Enabled Apache MPM:"

find /etc/apache2/mods-enabled \
    -maxdepth 1 \
    -type l \
    \( -name 'mpm_*.load' -o -name 'mpm_*.conf' \) \
    -printf '%f -> %l\n' || true

# ------------------------------------------------------------
# 2. SUITECRM PERSISTENT STORAGE
# ------------------------------------------------------------

mkdir -p "${APP_DIR}"

echo "[suitecrm] Checking SuiteCRM application files..."

# The marker is intentionally NOT used here.
#
# The real test is index.php.
#
# This protects against a persistent volume that contains
# the old marker but does not contain the SuiteCRM application.

if [[ ! -f "${APP_DIR}/index.php" ]]; then

    echo "[suitecrm] SuiteCRM application files not found."
    echo "[suitecrm] Initializing application from image..."

    if [[ -d "${SEED_DIR}" ]] && [[ -f "${SEED_DIR}/index.php" ]]; then

        echo "[suitecrm] Copying SuiteCRM files to persistent volume..."

        cp -a "${SEED_DIR}/." "${APP_DIR}/"

        echo "[suitecrm] SuiteCRM application copied successfully."

    else

        echo "[suitecrm] ERROR: SuiteCRM image source is missing!"
        echo "[suitecrm] Expected file:"
        echo "           ${SEED_DIR}/index.php"

        exit 1

    fi

else

    echo "[suitecrm] Existing SuiteCRM installation detected."
    echo "[suitecrm] Application files found:"
    echo "           ${APP_DIR}/index.php"

fi

# ------------------------------------------------------------
# 3. BASIC FILE VALIDATION
# ------------------------------------------------------------

if [[ ! -f "${APP_DIR}/index.php" ]]; then

    echo "[suitecrm] ERROR: index.php is still missing!"
    echo "[suitecrm] SuiteCRM cannot start."

    exit 1

fi

echo "[suitecrm] SuiteCRM index.php detected."

# ------------------------------------------------------------
# 4. PERMISSIONS
# ------------------------------------------------------------

echo "[suitecrm] Fixing permissions..."

# General ownership.
chown -R www-data:www-data "${APP_DIR}"

# General permissions.
chmod -R 755 "${APP_DIR}"

# SuiteCRM writable directories.
for DIR in \
    cache \
    custom \
    data \
    upload
do

    if [[ -d "${APP_DIR}/${DIR}" ]]; then

        chmod -R 775 "${APP_DIR}/${DIR}"

    fi

done

# ------------------------------------------------------------
# 5. CONFIGURATION FILE
# ------------------------------------------------------------

# Do NOT create config.php automatically.
#
# SuiteCRM's installer creates it when necessary.
#
# If it already exists, make sure Apache/PHP can update it.

if [[ -f "${APP_DIR}/config.php" ]]; then

    chown www-data:www-data "${APP_DIR}/config.php"
    chmod 664 "${APP_DIR}/config.php"

    echo "[suitecrm] Existing config.php detected."

else

    echo "[suitecrm] config.php not found."
    echo "[suitecrm] SuiteCRM installer will create it."

fi

# ------------------------------------------------------------
# 6. SUITECRM CRON
# ------------------------------------------------------------

echo "[suitecrm] Starting SuiteCRM scheduler..."

if [[ -x "/usr/local/bin/suitecrm-cron.sh" ]]; then

    /usr/local/bin/suitecrm-cron.sh &

else

    echo "[suitecrm] WARNING: suitecrm-cron.sh not found."

fi

# ------------------------------------------------------------
# 7. APACHE VALIDATION
# ------------------------------------------------------------

echo "[suitecrm] Validating Apache configuration..."

apache2ctl -t

echo "[suitecrm] Apache MPM modules detected:"

apache2ctl -M 2>&1 \
    | grep -E 'mpm_(event|worker|prefork)_module' \
    || true

# ------------------------------------------------------------
# 8. SUITECRM FILE CHECK
# ------------------------------------------------------------

echo "[suitecrm] SuiteCRM files:"

ls -lah \
    "${APP_DIR}/index.php" \
    2>/dev/null || true

if [[ -f "${APP_DIR}/config.php" ]]; then

    ls -lah "${APP_DIR}/config.php"

fi

# ------------------------------------------------------------
# 9. START APACHE
# ------------------------------------------------------------

echo "[suitecrm] Starting Apache..."

exec "$@"
