#!/bin/sh
set -e

# Ensure runtime directory exists (tmpfs is remounted on each start)
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

SOCKET=/run/mysqld/mysqld.sock
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# First-boot initialisation: populate the data directory
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[init] Initialising MariaDB data directory..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    # Start a temporary instance (no networking) to bootstrap the DB
    mysqld --user=mysql --skip-networking --socket="$SOCKET" &
    TEMP_PID=$!

    # Wait up to 30 s for mysqld to accept connections
    i=0
    while ! mysqladmin --socket="$SOCKET" ping --silent 2>/dev/null; do
        i=$((i + 1))
        if [ "$i" -ge 30 ]; then
            echo "[init] ERROR: MariaDB did not start in time" >&2
            exit 1
        fi
        sleep 1
    done

    # Bootstrap: set root password, create application DB and user
    mysql --socket="$SOCKET" -u root <<-SQL
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
        CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
        CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
        GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
        FLUSH PRIVILEGES;
SQL

    # Shut down the temporary instance gracefully
    mysqladmin --socket="$SOCKET" -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait "$TEMP_PID" || true
    echo "[init] Initialisation complete."
fi

# Hand off to mysqld as PID 1
exec mysqld --user=mysql
