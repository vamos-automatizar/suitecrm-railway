#!/usr/bin/env bash
set -Eeuo pipefail

cd /var/www/html

while true; do
  sleep 60
  if [[ -f config.php ]]; then
    /usr/local/bin/php -f cron.php >/dev/null 2>&1 || true
  fi
done
