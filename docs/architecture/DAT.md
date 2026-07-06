# Document d'Architecture Technique (DAT)
## Streaming Lab — Ynov Campus B3 INFRA

**Version :** 1.0  
**Date :** Juillet 2026  
**Équipe :** Iman Hamdy, Quentin, Adrien

---

## 1. Contexte et objectifs

Le projet Streaming Lab consiste à déployer une infrastructure complète de diffusion multimédia et de gestion d'identité sur un serveur physique dédié, dans le cadre du cursus B3 INFRA d'Ynov Campus.

**Objectifs :**
- Déployer une plateforme de streaming vidéo accessible depuis Internet
- Mettre en place une gestion centralisée des identités (SSO)
- Assurer la supervision et l'observabilité de l'infrastructure
- Garantir la sécurité des données et des accès

---

## 2. Infrastructure physique

### Serveur
| Composant | Valeur |
|-----------|--------|
| Modèle | Dell PowerEdge T140 |
| Hyperviseur | Proxmox VE 8.x |
| Hostname | `quentin` |

### Machines virtuelles

| VM | Rôle | OS | IP | VLAN | RAM | vCPU |
|----|------|----|----|------|-----|------|
| vm-streaming | Services applicatifs | Ubuntu 22.04 LTS | 192.168.10.2 | VLAN 10 | 8 Go | 2 |
| vm-dns | Résolution DNS interne | Ubuntu 22.04 LTS | 192.168.20.2 | VLAN 20 | 2 Go | 1 |
| vm-backup | Sauvegardes | Ubuntu 22.04 LTS | 192.168.30.2 | VLAN 30 | 2 Go | 1 |

---

## 3. Architecture réseau

### Topologie
```
Internet
    │
    ▼
Cloudflare (DNS + WAF + TLS)
    │  HTTPS (443)
    ▼
Cloudflare Tunnel (cloudflared)
    │  HTTP interne
    ▼
FortiGate (192.168.1.39)  ← Firewall / routeur
    │
    ├── VLAN 10 (192.168.10.0/24)  → vm-streaming
    ├── VLAN 20 (192.168.20.0/24)  → vm-dns
    └── VLAN 30 (192.168.30.0/24)  → vm-backup
```

### Flux TLS
Cloudflare termine le TLS côté public. Les échanges internes entre Cloudflare Tunnel et Traefik transitent en HTTP sur le réseau privé. Traefik agit comme reverse proxy HTTP uniquement.

### Réseaux Docker (vm-streaming)

| Réseau | Sous-réseau | Usage |
|--------|-------------|-------|
| `streaming-net` | 172.20.0.0/16 | Communication inter-services exposés |
| `db-net` | 172.19.0.0/16 | Bases de données (isolées) |
| `monitoring-net` | 172.18.0.0/16 | Stack d'observabilité |
| `storage-net` | 172.21.0.0/16 | Stockage objet |

---

## 4. Architecture applicative

### Vue d'ensemble des services

```
                    ┌──────────────────────────────────────────┐
                    │              vm-streaming                 │
                    │                                          │
  Cloudflare ──────►│  Traefik :80                            │
  Tunnel            │     │                                    │
                    │     ├──► Jellyfin :8096                 │
                    │     ├──► Keycloak :8080                 │
                    │     ├──► Grafana  :3000                 │
                    │     ├──► MinIO    :9001                 │
                    │     ├──► Vault    :8200                 │
                    │     └──► Traefik dashboard              │
                    │                                          │
                    │  ┌─── db-net ──────────────────┐        │
                    │  │  PostgreSQL  MongoDB  Redis  │        │
                    │  └─────────────────────────────┘        │
                    │                                          │
                    │  ┌─── monitoring-net ──────────┐        │
                    │  │  Prometheus  Loki  Grafana  │        │
                    │  └─────────────────────────────┘        │
                    └──────────────────────────────────────────┘
```

### Catalogue des services

| Service | Image | Rôle | Port interne | Domaine |
|---------|-------|------|-------------|---------|
| Traefik | `traefik:v3.3` | Reverse proxy HTTP | 80 | `traefik.duoowatch.com` |
| Jellyfin | `jellyfin/jellyfin:10.9` | Streaming multimédia | 8096 | `jellyfin.duoowatch.com` |
| Keycloak | `quay.io/keycloak/keycloak:24.0` | SSO / IAM | 8080 | `keycloak.duoowatch.com` |
| Grafana | `grafana/grafana:latest` | Tableaux de bord | 3000 | `grafana.duoowatch.com` |
| MinIO | `minio/minio:latest` | Stockage objet S3 | 9001 | `minio.duoowatch.com` |
| Vault | `hashicorp/vault:1.17` | Gestion des secrets | 8200 | `vault.duoowatch.com` |
| PostgreSQL | `postgres:17-alpine` | Base relationnelle | 5432 | Interne |
| MongoDB | `mongo:4.4` | Base documentaire | 27017 | Interne |
| Redis | `redis:7-alpine` | Cache / sessions | 6379 | Interne |
| Prometheus | `prom/prometheus:latest` | Collecte métriques | 9090 | Interne |
| Loki | `grafana/loki:latest` | Agrégation logs | 3100 | Interne |
| Promtail | `grafana/promtail:latest` | Collecteur logs | — | Interne |
| cAdvisor | `gcr.io/cadvisor/cadvisor` | Métriques containers | 8080 | Interne |
| Node Exporter | `prom/node-exporter` | Métriques système | 9100 | Interne |
| Alertmanager | `prom/alertmanager` | Gestion alertes | 9093 | Interne |
| Watchtower | `containrrr/watchtower` | Mises à jour auto | — | Interne |

---

## 5. Gestion des identités (IAM)

Keycloak assure le SSO (Single Sign-On) pour tous les services :

- **Realm :** `streaming-lab`
- **Clients OIDC :** Jellyfin, Grafana, MinIO
- **Protocol :** OpenID Connect (OIDC) / OAuth 2.0
- **Flux :** Authorization Code Flow avec PKCE

Les utilisateurs s'authentifient une seule fois sur Keycloak, le token JWT est propagé aux services.

---

## 6. Observabilité

### Stack (PLG)
```
Containers / Système
        │
        ├── Promtail ──────────► Loki ──────────► Grafana (logs)
        │
        └── cAdvisor           ┐
            Node Exporter      ├──► Prometheus ──► Grafana (métriques)
            Alertmanager ◄─────┘
```

- **Métriques :** Prometheus scrape toutes les 15s, rétention 15 jours
- **Logs :** Promtail collecte `/var/log` et les logs Docker JSON
- **Alertes :** Alertmanager gère les notifications

---

## 7. Sécurité

### Modèle de sécurité

| Couche | Mesure |
|--------|--------|
| Périmètre | Cloudflare WAF, DDoS protection |
| Transport | TLS 1.3 terminé chez Cloudflare |
| Reverse proxy | Traefik avec basic auth sur le dashboard |
| Authentification | Keycloak SSO, MFA configurable |
| Secrets | HashiCorp Vault |
| Bases de données | Users dédiés par service (pas de superuser) |
| Réseau Docker | Segmentation par réseau (db-net isolé) |

### Isolation réseau
Les bases de données sont sur `db-net` uniquement — les services exposés n'y ont pas accès direct, seulement via leurs propres composants backend.

### Gestion des secrets
- En développement : fichier `.env` (non versionné)
- En production : HashiCorp Vault avec injection dynamique de credentials

---

## 8. Haute disponibilité et sauvegarde

### Limites actuelles
L'infrastructure est mono-nœud (single point of failure sur le Dell T140). Une panne matérielle entraîne une interruption de service.

### Mesures de résilience
- `restart: unless-stopped` sur tous les containers
- Watchtower pour les mises à jour automatiques des images
- vm-backup dédiée aux sauvegardes des volumes Docker

### RTO / RPO cibles
| Indicateur | Objectif |
|-----------|---------|
| RTO (Recovery Time Objective) | < 30 minutes |
| RPO (Recovery Point Objective) | < 24 heures |

---

## 9. Déploiement et CI/CD

### Workflow Gitflow
```
main (production)
  └── develop (intégration)
        └── feature/* (développement)
```

### Déploiement sur vm-streaming
```bash
git pull origin develop
make up        # Démarre tous les stacks
make ps        # Vérification
```

### Makefile — commandes principales
| Commande | Action |
|----------|--------|
| `make up` | Démarre tous les stacks |
| `make down` | Arrête tous les stacks |
| `make up-proxy` | Démarre Traefik uniquement |
| `make logs-keycloak` | Logs Keycloak en temps réel |
| `make ps` | État de tous les containers |

---

## 10. Domaine et DNS

- **Domaine :** `duoowatch.com` (géré par Cloudflare)
- **Enregistrements :** CNAMEs pointant vers le tunnel Cloudflare
- **Tunnel :** `cloudflared` sur vm-streaming, connexion sortante vers Cloudflare

Aucun port entrant n'est ouvert sur le FortiGate — tout le trafic entrant passe par le tunnel Cloudflare.
