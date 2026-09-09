#!/usr/bin/env bash

set -Eeuo pipefail

APP_DIR="/var/www/html"
SEED_DIR="/opt/suitecrm"

echo "=========================================="
echo "SUITECRM ENTRYPOINT V8"
echo "BUILD SOURCE: vamos-automatizar/suitecrm-railway"
echo "DATE: 2026-09-09"
echo "=========================================="

echo "[suitecrm] Entrypoint started."

# ------------------------------------------------------------
# 1. FORCE APACHE PREFORK MPM
# ------------------------------------------------------------

echo "[suitecrm] Cleaning Apache MPM configuration..."

# Remove every enabled MPM module.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# Disable possible MPM modules.
a2dismod mpm_event 2>/dev/null || true
a2dismod mpm_worker 2>/dev/null || true
a2dismod mpm_prefork 2>/dev/null || true

# Remove them again to guarantee a clean state.
rm -f /etc/apache2/mods-enabled/mpm_*.load
rm -f /etc/apache2/mods-enabled/mpm_*.conf

# SuiteCRM with mod_php requires prefork.
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

# Do not rely on a marker file.
# The real validation is the presence of index.php.

if [[ ! -f "${APP_DIR}/index.php" ]]; then

    echo "[suitecrm] SuiteCRM application files not found."
    echo "[suitecrm] Initializing application from image..."

    if [[ -d "${SEED_DIR}" ]] && [[ -f "${SEED_DIR}/index.php" ]]; then

        echo "[suitecrm] Copying SuiteCRM files to persistent volume..."

        cp -a "${SEED_DIR}/." "${APP_DIR}/"

        echo "[suitecrm] SuiteCRM application copied successfully."

    else

        echo "[suitecrm] ERROR: SuiteCRM image source is missing."
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

    echo "[suitecrm] ERROR: index.php is still missing."
    echo "[suitecrm] SuiteCRM cannot start."

    exit 1

fi

echo "[suitecrm] SuiteCRM index.php detected."

# ------------------------------------------------------------
# 4. PHP TEMPORARY DIRECTORY
# ------------------------------------------------------------

echo "[suitecrm] Configuring PHP temporary directory..."

# Keep PHP temporary files on the same persistent filesystem
# as SuiteCRM cache files.
mkdir -p "${APP_DIR}/tmp"

echo "[suitecrm] Fixing temporary directory ownership..."

chown -R www-data:www-data "${APP_DIR}/tmp"

# Writable by owner and group.
chmod 775 "${APP_DIR}/tmp"

echo "[suitecrm] PHP temporary directory:"
ls -ld "${APP_DIR}/tmp"

# ------------------------------------------------------------
# 5. SYSTEM /tmp
# ------------------------------------------------------------

# Keep the system temporary directory usable as well.
# PHP should use ${APP_DIR}/tmp because of sys_temp_dir.

echo "[suitecrm] Checking system /tmp..."

mkdir -p /tmp
chmod 1777 /tmp

echo "[suitecrm] System /tmp:"
ls -ld /tmp

# ------------------------------------------------------------
# 6. FILE OWNERSHIP AND PERMISSIONS
# ------------------------------------------------------------

echo "[suitecrm] Fixing SuiteCRM permissions..."

# SuiteCRM application must be owned by Apache/PHP.
chown -R www-data:www-data "${APP_DIR}"

# Default permissions:
# directories = 755
# files       = 644
find "${APP_DIR}" -type d -exec chmod 755 {} \;
find "${APP_DIR}" -type f -exec chmod 644 {} \;

# Restore the temporary directory permissions after
# applying the default application permissions.
chown -R www-data:www-data "${APP_DIR}/tmp"
chmod 775 "${APP_DIR}/tmp"

# ------------------------------------------------------------
# 7. SUITECRM WRITABLE DIRECTORIES
# ------------------------------------------------------------

for DIR in \
    cache \
    custom \
    modules \
    themes \
    data \
    upload
do

    if [[ -d "${APP_DIR}/${DIR}" ]]; then

        echo "[suitecrm] Configuring writable directory: ${DIR}"

        chown -R www-data:www-data "${APP_DIR}/${DIR}"
        chmod -R 775 "${APP_DIR}/${DIR}"

    else

        echo "[suitecrm] WARNING: directory not found: ${DIR}"

    fi

done

# ------------------------------------------------------------
# 8. CONFIGURATION FILE
# ------------------------------------------------------------

# Do not create config.php automatically.
# SuiteCRM installer creates it when required.

if [[ -f "${APP_DIR}/config.php" ]]; then

    echo "[suitecrm] Existing config.php detected."

    chown www-data:www-data "${APP_DIR}/config.php"
    chmod 664 "${APP_DIR}/config.php"

else

    echo "[suitecrm] config.php not found."
    echo "[suitecrm] SuiteCRM installer will create it."

fi

# ------------------------------------------------------------
# 9. PHP TEMP DIRECTORY VALIDATION
# ------------------------------------------------------------

echo "[suitecrm] Checking PHP sys_temp_dir..."

PHP_TEMP_DIR="$(php -r 'echo sys_get_temp_dir();')"

echo "[suitecrm] PHP reports temporary directory:"
echo "           ${PHP_TEMP_DIR}"

if [[ "${PHP_TEMP_DIR}" != "${APP_DIR}/tmp" ]]; then

    echo "[suitecrm] ERROR: PHP is not using the SuiteCRM persistent temp directory."
    echo "[suitecrm] Expected: ${APP_DIR}/tmp"
    echo "[suitecrm] Actual:   ${PHP_TEMP_DIR}"

    exit 1

fi

echo "[suitecrm] PHP sys_temp_dir configuration: OK"

# ------------------------------------------------------------
# 10. PHP TEMP FILE TEST
# ------------------------------------------------------------

echo "[suitecrm] Testing PHP temporary file creation..."

TEMP_TEST="$(su -s /bin/sh www-data -c \
    'php -r "echo tempnam(sys_get_temp_dir(), \"suitecrm\");"')"

echo "[suitecrm] PHP temp test:"
echo "           ${TEMP_TEST}"

if [[ "${TEMP_TEST}" != "${APP_DIR}/tmp/"* ]]; then

    echo "[suitecrm] ERROR: PHP temporary file was not created inside ${APP_DIR}/tmp."

    rm -f "${TEMP_TEST}" 2>/dev/null || true

    exit 1

fi

if [[ ! -f "${TEMP_TEST}" ]]; then

    echo "[suitecrm] ERROR: PHP temporary file does not exist."

    exit 1

fi

rm -f "${TEMP_TEST}"

echo "[suitecrm] PHP temporary file test: OK"

# ------------------------------------------------------------
# 11. CACHE WRITE TEST
# ------------------------------------------------------------

echo "[suitecrm] Validating SuiteCRM cache directory..."

mkdir -p "${APP_DIR}/cache"

chown -R www-data:www-data "${APP_DIR}/cache"
chmod -R 775 "${APP_DIR}/cache"

CACHE_TEST_DIR="${APP_DIR}/cache/.railway-write-test"

rm -rf "${CACHE_TEST_DIR}"

if su -s /bin/sh www-data -c \
    "mkdir -p '${CACHE_TEST_DIR}' && touch '${CACHE_TEST_DIR}/test.php'"
then

    echo "[suitecrm] Cache write test: OK"

    rm -rf "${CACHE_TEST_DIR}"

else

    echo "[suitecrm] ERROR: SuiteCRM cache is not writable by www-data."

    rm -rf "${CACHE_TEST_DIR}"

    exit 1

fi

# ------------------------------------------------------------
# 12. CACHE MODULES WRITE TEST
# ------------------------------------------------------------

echo "[suitecrm] Validating cache/modules directory..."

mkdir -p "${APP_DIR}/cache/modules"

chown -R www-data:www-data "${APP_DIR}/cache/modules"
chmod -R 775 "${APP_DIR}/cache/modules"

CACHE_MODULE_TEST_DIR="${APP_DIR}/cache/modules/.railway-write-test"

rm -rf "${CACHE_MODULE_TEST_DIR}"

if su -s /bin/sh www-data -c \
    "mkdir -p '${CACHE_MODULE_TEST_DIR}' && touch '${CACHE_MODULE_TEST_DIR}/test.php'"
then

    echo "[suitecrm] Cache modules write test: OK"

    rm -rf "${CACHE_MODULE_TEST_DIR}"

else

    echo "[suitecrm] ERROR: cache/modules is not writable by www-data."

    rm -rf "${CACHE_MODULE_TEST_DIR}"

    exit 1

fi

# ------------------------------------------------------------
# 13. SUITECRM CRON
# ------------------------------------------------------------

echo "[suitecrm] Starting SuiteCRM scheduler..."

if [[ -x "/usr/local/bin/suitecrm-cron.sh" ]]; then

    /usr/local/bin/suitecrm-cron.sh &

    echo "[suitecrm] SuiteCRM scheduler started."

else

    echo "[suitecrm] WARNING: suitecrm-cron.sh not found."

fi

# ------------------------------------------------------------
# 14. APACHE CONFIGURATION VALIDATION
# ------------------------------------------------------------

echo "[suitecrm] Validating Apache configuration..."

apache2ctl -t

echo "[suitecrm] Apache MPM modules detected:"

apache2ctl -M 2>&1 \
    | grep -E 'mpm_(event|worker|prefork)_module' \
    || true

# ------------------------------------------------------------
# 15. FINAL SUITECRM VALIDATION
# ------------------------------------------------------------

echo "[suitecrm] Final SuiteCRM validation..."

echo "[suitecrm] Application root:"
ls -ld "${APP_DIR}"

echo "[suitecrm] index.php:"
ls -lah "${APP_DIR}/index.php"

echo "[suitecrm] PHP temp directory:"
ls -ld "${APP_DIR}/tmp"

echo "[suitecrm] SuiteCRM cache:"
ls -ld "${APP_DIR}/cache"

echo "[suitecrm] SuiteCRM cache/modules:"
ls -ld "${APP_DIR}/cache/modules"

if [[ -f "${APP_DIR}/config.php" ]]; then

    echo "[suitecrm] config.php:"
    ls -lah "${APP_DIR}/config.php"

else

    echo "[suitecrm] config.php: not created yet"

fi

# ------------------------------------------------------------
# 16. START APACHE
# ------------------------------------------------------------

echo "[suitecrm] Starting Apache..."

exec "$@"
