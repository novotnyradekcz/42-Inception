# Developer Documentation

## Setting up the environment from scratch

### Prerequisites

| Requirement | Minimum version |
|---|---|
| Docker Engine | 25.x |
| Docker Compose plugin | v2.x |
| `make` | any |
| `sudo` | required for host data dirs and volume cleanup |

Install Docker on Debian/Ubuntu:

```sh
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # re-login after this
```

### Configuration files

| File | Purpose | In git? |
|---|---|---|
| `srcs/.env` | Non-sensitive env vars (domain, DB name, WP usernames) | **No** — gitignored |
| `secrets/db_password.txt` | MariaDB `wpuser` password | **No** — gitignored |
| `secrets/db_root_password.txt` | MariaDB `root` password | **No** — gitignored |
| `secrets/credentials.txt` | WordPress admin + user passwords | **No** — gitignored |

After cloning the repository you must recreate these files manually. Reference the template below or copy from a secure store.

#### `srcs/.env` template

```dotenv
DOMAIN_NAME=rnovotny.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser

WP_TITLE=rnovotny's Inception
WP_ADMIN_USER=rnovotny_wp
WP_ADMIN_EMAIL=admin@rnovotny.42.fr
WP_USER=rnovotny
WP_USER_EMAIL=rnovotny@rnovotny.42.fr
```

#### `secrets/` template

```sh
echo "YourDbUserPassword"   > secrets/db_password.txt
echo "YourDbRootPassword"   > secrets/db_root_password.txt
printf 'WP_ADMIN_PASSWORD=YourWpAdminPass\nWP_USER_PASSWORD=YourWpUserPass\n' \
    > secrets/credentials.txt
```

### Domain resolution

Add the domain to `/etc/hosts` on the VM:

```sh
echo "127.0.0.1 rnovotny.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and launching the project

```sh
# Full build + start (also creates host data directories)
make

# Equivalent manual command
mkdir -p /home/rnovotny/data/mariadb /home/rnovotny/data/wordpress
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d --build
```

The first `make` takes a few minutes because it downloads Alpine base images, installs packages, and on the first container start, WordPress core is downloaded and installed automatically.

### Makefile targets

| Target | Action |
|---|---|
| `make` / `make all` | Build images + start containers |
| `make up` | Same as `all` |
| `make down` | Stop and remove containers (data + images preserved) |
| `make clean` | Stop and remove containers + built images |
| `make fclean` | `clean` + remove named volumes + delete `/home/rnovotny/data/` |
| `make re` | `fclean` then `all` |

---

## Managing containers and volumes

### Common Docker Compose commands

```sh
# Status
docker compose --env-file srcs/.env -f srcs/docker-compose.yml ps

# Follow logs in real time
docker compose --env-file srcs/.env -f srcs/docker-compose.yml logs -f

# Restart a single service
docker compose --env-file srcs/.env -f srcs/docker-compose.yml restart wordpress

# Rebuild a single image without stopping others
docker compose --env-file srcs/.env -f srcs/docker-compose.yml build mariadb
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d mariadb
```

### Entering a running container

```sh
docker exec -it nginx      sh
docker exec -it wordpress  sh
docker exec -it mariadb    sh
```

### Volume inspection

```sh
# List volumes
docker volume ls

# Inspect a volume (shows mountpoint and driver options)
docker volume inspect wp-database
docker volume inspect wp-files
```

### Manually connecting to MariaDB

```sh
# From outside the container (mariadb-client must be installed on the host)
docker exec -it mariadb mariadb -u wpuser -p wordpress

# Or as root
docker exec -it mariadb mariadb -u root -p
```

---

## Where data is stored and how it persists

### Named volumes

Two Docker named volumes are defined in `srcs/docker-compose.yml`:

| Volume name | Mounted at (container) | Host path |
|---|---|---|
| `wp-database` | `/var/lib/mysql` (mariadb) | `/home/rnovotny/data/mariadb` |
| `wp-files` | `/var/www/html` (wordpress, nginx) | `/home/rnovotny/data/wordpress` |

The volumes use `driver: local` with `type: none, o: bind` so Docker treats them as named volumes (portable, managed lifecycle) while the actual bytes live at the specified host path. This satisfies the subject requirement of storing data under `/home/rnovotny/data`.

### Persistence across restarts

- `make down` stops containers but leaves volumes and host data intact. All WordPress content and the database survive.
- `make clean` additionally removes built images. Data is still intact.
- `make fclean` wipes everything including host data — use only for a clean slate.

### First-boot vs subsequent starts

Each entrypoint script (`init.sh`, `wp-install.sh`) checks for a sentinel file or directory before running the initialisation logic:

- **MariaDB** — checks for `/var/lib/mysql/mysql` (the system database). If absent, runs `mysql_install_db` and bootstraps the application database.
- **WordPress** — checks for `/var/www/html/wp-config.php`. If absent, downloads WordPress core, creates `wp-config.php`, installs WordPress, and creates both users.

After the first boot these checks are skipped and the daemons start immediately.

### Project structure overview

```
Inception/
├── Makefile                          ← orchestration entry point
├── .gitignore
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                          ← gitignored — never commit
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env                          ← gitignored — better not to commit
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/nginx.conf       ← TLS + FastCGI config
        │   └── tools/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/50-server.cnf    ← MariaDB server config
        │   └── tools/init.sh         ← first-boot init + PID 1 exec
        └── wordpress/
            ├── Dockerfile
            ├── conf/www.conf         ← PHP-FPM pool config
            └── tools/wp-install.sh   ← WP install + PID 1 exec
```
