.PHONY: up down restart logs ps pull

DOCKER_DIR := docker

up-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml up -d

down-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml down

restart-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml restart

logs-%:
	docker compose -f $(DOCKER_DIR)/$*/docker-compose.yml logs -f

ps:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

up: up-proxy up-databases up-keycloak up-jellyfin up-monitoring up-security up-storage

down:
	@for stack in proxy databases keycloak jellyfin monitoring security storage; do \
		docker compose -f $(DOCKER_DIR)/$$stack/docker-compose.yml down; \
	done

pull:
	@for stack in proxy databases keycloak jellyfin monitoring security storage; do \
		docker compose -f $(DOCKER_DIR)/$$stack/docker-compose.yml pull; \
	done
