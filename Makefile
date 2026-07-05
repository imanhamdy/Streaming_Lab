.PHONY: up down restart logs ps pull

DOCKER_DIR := docker
ENV_FILE   := .env

up-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml --env-file $(ENV_FILE) up -d

down-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml --env-file $(ENV_FILE) down

restart-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml --env-file $(ENV_FILE) restart

logs-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml --env-file $(ENV_FILE) logs -f

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

up: up-proxy up-databases up-keycloak up-jellyfin up-monitoring up-security up-storage

down:
	@for stack in proxy databases keycloak jellyfin monitoring security storage; do \
		docker compose -f $(DOCKER_DIR)/$$stack/docker-compose.yml --env-file $(ENV_FILE) down; \
	done

pull:
	@for stack in proxy databases keycloak jellyfin monitoring security storage; do \
		docker compose -f $(DOCKER_DIR)/$$stack/docker-compose.yml --env-file $(ENV_FILE) pull; \
	done
