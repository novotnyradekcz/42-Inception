#!/bin/sh
set -e

# Read secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/credentials | cut -d'=' -f2-)
WP_USER_PASSWORD=$(grep '^WP_USER_PASSWORD='  /run/secrets/credentials | cut -d'=' -f2-)

WP_PATH=/var/www/html

# Wait for MariaDB to accept TCP connections
echo "[wp] Waiting for MariaDB..."
i=0
while ! nc -z mariadb 3306 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
        echo "[wp] ERROR: MariaDB not reachable after 60 s" >&2
        exit 1
    fi
    sleep 2
done
echo "[wp] MariaDB is up."

# Install WordPress only on first boot
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "[wp] Downloading WordPress core..."
    wp core download \
        --path="$WP_PATH" \
        --locale=en_US \
        --allow-root

    echo "[wp] Creating wp-config.php..."
    wp config create \
        --path="$WP_PATH" \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    echo "[wp] Installing WordPress..."
    wp core install \
        --path="$WP_PATH" \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    echo "[wp] Creating regular user '${WP_USER}'..."
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --path="$WP_PATH" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}" \
        --allow-root

    chown -R nobody:nobody "$WP_PATH"
    echo "[wp] WordPress installation complete."
fi

# Hand off to PHP-FPM as PID 1 (no daemonise flag = -F)
exec php-fpm83 -F
