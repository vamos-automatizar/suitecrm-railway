#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/var/www/html
SEED_DIR=/opt/suitecrm
MARKER="$APP_DIR/.suitecrm-seeded"

mkdir -p "$APP_DIR"

# The Railway volume is mounted over /var/www/html and hides files baked into the image.
# Seed the volume only on its first initialization.
if [[ ! -f "$MARKER" ]]; then
    if [[ -f "$APP_DIR/suitecrm_version.php" ]]; then
        echo "[suitecrm] Existing SuiteCRM files detected; preserving persistent volume."
    else
        echo "[suitecrm] Initializing persistent application volume..."
        cp -a "$SEED_DIR/." "$APP_DIR/"
    fi

    touch "$MARKER"
fi

# SuiteCRM requires the web server to be able to write to these paths.
chown -R www-data:www-data "$APP_DIR"

chmod -R 755 "$APP_DIR"

chmod -R 775 \
    "$APP_DIR/cache" \
    "$APP_DIR/custom" \
    "$APP_DIR/modules" \
    "$APP_DIR/themes" \
    "$APP_DIR/data" \
    "$APP_DIR/upload" 2>/dev/null || true

# The official installer creates/updates config.php.
touch "$APP_DIR/config.php"

chown www-data:www-data "$APP_DIR/config.php"
chmod 664 "$APP_DIR/config.php"

# Run SuiteCRM cron every minute in the background.
/usr/local/bin/suitecrm-cron.sh &

exec "$@"
