NAME    = inception
COMPOSE = docker compose --env-file srcs/.env -f srcs/docker-compose.yml
DATA    = /home/rnovotny/data

all: up

up:
	@mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --rmi all --remove-orphans

fclean: clean
	docker volume rm wp-database wp-files 2>/dev/null || true
	@sudo rm -rf $(DATA)/mariadb $(DATA)/wordpress

re: fclean all

.PHONY: all up down clean fclean re
