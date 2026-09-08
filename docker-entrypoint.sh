#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR=/var/www/html
SEED_DIR=/opt/suitecrm
MARKER="$APP_DIR/.suitecrm-seeded"

mkdir -p "$APP_DIR"

# Seed the persistent application volume only once for this SuiteCRM version.
# This keeps the public template reproducible while preserving user data/customizations.
if [[ ! -f "$MARKER" ]]; then
  if [[ ! -f "$APP_DIR/suitecrm_version.php" ]]; then
    echo "[suitecrm] Initializing persistent application volume..."
    cp -a "$SEED_DIR/." "$APP_DIR/"
  else
    echo "[suitecrm] Existing SuiteCRM installation detected; preserving volume contents."
  fi
  touch "$MARKER"
fi

# SuiteCRM requires these paths to be writable by the web server.
chown -R www-data:www-data "$APP_DIR"
chmod -R 755 "$APP_DIR"
chmod -R 775 \
  "$APP_DIR/cache" \
  "$APP_DIR/custom" \
  "$APP_DIR/modules" \
  "$APP_DIR/themes" \
  "$APP_DIR/data" \
  "$APP_DIR/upload" 2>/dev/null || true

# config.php is created/updated by the official web installer.
touch "$APP_DIR/config.php"
chown www-data:www-data "$APP_DIR/config.php"
chmod 664 "$APP_DIR/config.php"

# Start SuiteCRM's required scheduled task runner in the background.
# It runs once per minute, matching the official installation guidance.
/usr/local/bin/suitecrm-cron.sh &

exec "$@"
