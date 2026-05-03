# User & Administrator Documentation

## What services does this stack provide?

| Container | Service | Port |
|---|---|---|
| `nginx` | HTTPS reverse proxy with TLS 1.2/1.3 | 443 (host-facing) |
| `wordpress` | WordPress application + PHP-FPM | 9000 (internal only) |
| `mariadb` | MySQL-compatible database | 3306 (internal only) |

Only port **443** is exposed to the host. All other inter-container communication happens over the private `inception` Docker network.

---

## Starting and stopping the project

From the root of the repository:

```sh
# Build images and start all three containers in the background
make

# Stop containers without removing data
make down

# Stop and remove built images (data is preserved)
make clean

# Stop, remove images AND delete all persistent data (full reset)
make fclean

# Full clean rebuild
make re
```

You can also use Docker Compose directly:

```sh
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d
docker compose --env-file srcs/.env -f srcs/docker-compose.yml down
```

---

## Accessing the website and admin panel

Before the first run, add the domain to your `/etc/hosts`:

```sh
echo "127.0.0.1 rnovotny.42.fr" | sudo tee -a /etc/hosts
```

| URL | Purpose |
|---|---|
| `https://rnovotny.42.fr` | WordPress front page |
| `https://rnovotny.42.fr/wp-admin` | WordPress administration panel |

The site uses a **self-signed TLS certificate**. Your browser will show a security warning — click "Advanced → Accept the risk" (Firefox) or "Proceed anyway" (Chrome) to continue.

---

## Locating and managing credentials

All credentials are stored in the `secrets/` directory at the project root.

| File | What it contains |
|---|---|
| `secrets/db_password.txt` | Password for the `wpuser` MariaDB account |
| `secrets/db_root_password.txt` | Password for the MariaDB `root` account |
| `secrets/credentials.txt` | WordPress admin password (`WP_ADMIN_PASSWORD`) and regular user password (`WP_USER_PASSWORD`) |

Non-sensitive configuration (domain name, DB name, WP usernames, emails) is in `srcs/.env`.

**WordPress users:**

| Username | Role | Email |
|---|---|---|
| `rnovotny_wp` | Administrator | `admin@rnovotny.42.fr` |
| `rnovotny` | Author | `rnovotny@rnovotny.42.fr` |

> **Security reminder:** The `secrets/` directory and `srcs/.env` are listed in `.gitignore` and must never be committed to a public repository.

---

## Checking that the services are running correctly

### Container status

```sh
docker ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should show status `Up`.

### Container logs

```sh
# All services at once
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs

# Individual service
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Connectivity checks

```sh
# Verify TLS is working and only TLS 1.2/1.3 is accepted
curl -k -v https://rnovotny.42.fr 2>&1 | grep -E "SSL|TLS|HTTP"

# Confirm TLS 1.1 is rejected (should fail)
curl -k --tlsv1.1 --tls-max 1.1 https://rnovotny.42.fr

# Connect to MariaDB from inside the container
docker exec -it mariadb mariadb -u wpuser -p <password from secrets/db_password.txt> wordpress
```

### Volume data location

Persistent data is stored on the host at:

```
/home/rnovotny/data/mariadb/    ← MariaDB database files
/home/rnovotny/data/wordpress/  ← WordPress site files
```
