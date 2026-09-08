#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/var/www/html"
SEED_DIR="/opt/suitecrm"
MARKER="${APP_DIR}/.suitecrm-seeded"

echo "[suitecrm] Entrypoint started."

mkdir -p "${APP_DIR}"

# Railway mounts the persistent volume over /var/www/html.
# On the first startup, copy the application from the image
# into the persistent volume.
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

# Ensure SuiteCRM can write to the directories required
# by the application and installer.
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

# config.php is created/updated by the SuiteCRM installer.
if [[ ! -f "${APP_DIR}/config.php" ]]; then
    touch "${APP_DIR}/config.php"
fi

chown www-data:www-data "${APP_DIR}/config.php"
chmod 664 "${APP_DIR}/config.php"

echo "[suitecrm] Starting SuiteCRM scheduler..."

if [[ -x "/usr/local/bin/suitecrm-cron.sh" ]]; then
    /usr/local/bin/suitecrm-cron.sh &
fi

echo "[suitecrm] Starting Apache..."

exec "$@"
