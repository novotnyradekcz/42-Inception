*This project has been created as part of the 42 curriculum by rnovotny.*

---

# Inception

## Description

Inception is a system administration project that builds a small web infrastructure entirely from Docker containers, without using any pre-made images (except the Alpine base). The stack consists of:

- **NGINX** — the sole entrypoint, serving HTTPS (TLS 1.2/1.3) on port 443, forwarding PHP requests to WordPress via FastCGI.
- **WordPress + PHP-FPM** — the application layer, isolated from NGINX with no web server of its own.
- **MariaDB** — the database layer, accessible only over the internal Docker network.

All data is persisted in named Docker volumes backed by `/home/rnovotny/data` on the host. Sensitive credentials are stored as Docker secrets and never appear in Dockerfiles or environment variables.

### Project Description

#### Virtual Machines vs Docker

| | Virtual Machine | Docker Container |
|---|---|---|
| Isolation | Full OS kernel + hardware virtualisation | Process-level isolation, shares host kernel |
| Boot time | Minutes | Milliseconds |
| Resource usage | Heavy (GBs of RAM per VM) | Lightweight (MBs) |
| Portability | Image is OS-specific | Image runs anywhere Docker runs |
| Use case | Strong security boundary, legacy software | Microservices, CI/CD, reproducible builds |

VMs are heavier but provide stronger isolation. Docker containers share the host kernel, making them faster and more resource-efficient.

#### Secrets vs Environment Variables

| | Docker Secrets | Environment Variables |
|---|---|---|
| Storage in container | `tmpfs` at `/run/secrets/` (memory only) | Process environment (`/proc/<pid>/environ`) |
| Visible in `docker inspect` | No | Yes |
| Visible in logs/history | No | Potentially yes |
| Use case | Passwords, API keys, certificates | Non-sensitive config (domain name, DB name) |

This project stores all passwords as Docker secrets. Non-sensitive configuration (`DOMAIN_NAME`, `MYSQL_DATABASE`, etc.) lives in `srcs/.env`.

#### Docker Network vs Host Network

| | Docker Bridge Network (`inception`) | Host Network |
|---|---|---|
| Isolation | Each container gets its own virtual NIC | Container shares the host's network namespace |
| Port mapping | Explicit (`443:443`) | None needed — ports are host ports |
| Security | Containers communicate only via the defined network | Any port the container opens is exposed on the host |
| Forbidden by subject | No | Yes — `network: host` is explicitly prohibited |

A custom bridge network (`inception`) is used. Containers resolve each other by service name (e.g. `mariadb`, `wordpress`).

#### Docker Volumes vs Bind Mounts

| | Named Volumes | Bind Mounts |
|---|---|---|
| Managed by Docker | Yes | No |
| Portability | Fully portable | Depends on host path existing |
| Subject requirement | Required | Forbidden |
| Data location | Docker storage area (or custom `device`) | Any host path |
| Permissions | Docker initialises from image | Must pre-exist on host |

Named volumes with `driver: local` + `driver_opts type: none, o: bind` are used to satisfy both requirements: Docker manages the volume metadata while data is stored at `/home/rnovotny/data/{mariadb,wordpress}`.

---

## Instructions

### Prerequisites

- Docker Engine ≥ 25 with the Compose plugin
- `sudo` access (to create `/home/rnovotny/data/` and manage volumes)
- `rnovotny.42.fr` resolving to `127.0.0.1` in `/etc/hosts`

### Quick start

```sh
# Add domain resolution (one-time)
echo "127.0.0.1 rnovotny.42.fr" | sudo tee -a /etc/hosts

# Build images and start all containers
make

# Open the site (accept the self-signed certificate warning)
# https://rnovotny.42.fr
```

### Stop / rebuild

```sh
make down        # stop containers (data preserved)
make clean       # stop + remove built images
make fclean      # stop + remove images + volumes + host data
make re          # full clean rebuild
```

### Credentials

All passwords should be in the a `secrets/` directory (gitignored).

| File | Content |
|---|---|
| `secrets/db_password.txt` | MariaDB `wpuser` password |
| `secrets/db_root_password.txt` | MariaDB `root` password |
| `secrets/credentials.txt` | WordPress admin + user passwords |

---

## Resources

### Docker & system administration

- [Docker official docs](https://docs.docker.com/)
- [Docker Compose reference](https://docs.docker.com/compose/compose-file/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Alpine Linux packages](https://pkgs.alpinelinux.org/packages)
- [NGINX docs](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WP-CLI commands](https://developer.wordpress.org/cli/commands/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

### AI usage

GitHub Copilot (Claude Sonnet 4.6) was used during this project for:

- **Scaffolding** — generating the initial directory structure and file skeletons based on the subject requirements.
- **Dockerfile authoring** — suggesting correct Alpine package names and PHP-FPM configuration for Alpine 3.21.
- **Shell scripts** — drafting `init.sh` and `wp-install.sh` entrypoint patterns (PID 1 handoff via `exec`, secret reading, readiness loops).
- **Documentation** — writing and structuring README, USER_DOC, and DEV_DOC files.

All generated content was reviewed, understood, and adjusted before inclusion. The correctness of package names, paths, and runtime behaviour was verified by running the containers on an actual VM.
