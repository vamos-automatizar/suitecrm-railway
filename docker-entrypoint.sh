#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/var/www/html"
SEED_DIR="/opt/suitecrm"
MARKER="${APP_DIR}/.suitecrm-seeded"

echo "=========================================="
echo "SUITECRM ENTRYPOINT V5"
echo "BUILD SOURCE: vamos-automatizar/suitecrm-railway"
echo "DATE: 2026-09-08"
echo "=========================================="

echo "[suitecrm] Entrypoint started."

# ------------------------------------------------------------
# 1. FORCE APACHE PREFORK MPM
# ------------------------------------------------------------

echo "[suitecrm] Cleaning Apache MPM configuration..."

# Remove any enabled MPM module, regardless of how it was enabled.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# Disable using a2dismod as an additional safety layer.
a2dismod mpm_event 2>/dev/null || true
a2dismod mpm_worker 2>/dev/null || true
a2dismod mpm_prefork 2>/dev/null || true

# Remove again in case a2dismod left anything behind.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# Enable ONLY prefork.
a2enmod mpm_prefork

echo "[suitecrm] Enabled Apache MPM:"
find /etc/apache2/mods-enabled -maxdepth 1 \
    -type l \
    \( -name 'mpm_*.load' -o -name 'mpm_*.conf' \) \
    -printf '%f -> %l\n' || true

# ------------------------------------------------------------
# 2. SUITECRM PERSISTENT STORAGE
# ------------------------------------------------------------

mkdir -p "${APP_DIR}"

if [[ ! -f "${MARKER}" ]]; then

    echo "[suitecrm] First initialization detected."

    if [[ -n "$(ls -A "${APP_DIR}" 2>/dev/null)" ]]; then
        echo "[suitecrm] Persistent volume is not empty."
    else
        echo "[suitecrm] Copying SuiteCRM files to persistent volume..."
        cp -a "${SEED_DIR}/." "${APP_DIR}/"
    fi

    touch "${MARKER}"

else
    echo "[suitecrm] Existing SuiteCRM installation detected."
fi

# ------------------------------------------------------------
# 3. PERMISSIONS
# ------------------------------------------------------------

echo "[suitecrm] Fixing permissions..."

chown -R www-data:www-data "${APP_DIR}"
chmod -R 755 "${APP_DIR}"

for DIR in \
    cache \
    custom \
    modules \
    themes \
    data \
    upload
do
    if [[ -d "${APP_DIR}/${DIR}" ]]; then
        chmod -R 775 "${APP_DIR}/${DIR}"
    fi
done

# config.php
if [[ ! -f "${APP_DIR}/config.php" ]]; then
    touch "${APP_DIR}/config.php"
fi

chown www-data:www-data "${APP_DIR}/config.php"
chmod 664 "${APP_DIR}/config.php"

# ------------------------------------------------------------
# 4. SUITECRM CRON
# ------------------------------------------------------------

echo "[suitecrm] Starting SuiteCRM scheduler..."

if [[ -x "/usr/local/bin/suitecrm-cron.sh" ]]; then
    /usr/local/bin/suitecrm-cron.sh &
fi

# ------------------------------------------------------------
# 5. APACHE VALIDATION
# ------------------------------------------------------------

echo "[suitecrm] Validating Apache configuration..."

apache2ctl -t

echo "[suitecrm] Apache MPM modules detected:"
apache2ctl -M 2>&1 | grep 'mpm_' || true

echo "[suitecrm] Starting Apache..."

exec "$@"
