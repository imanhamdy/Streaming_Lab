# Document d'Architecture Technique (DAT)
## Streaming Lab — Ynov Campus B3 INFRA

**Version :** 2.0  
**Date :** Juillet 2026  
**Équipe :** Iman Hamdy, Quentin, Adrien

---

## 1. Contexte et objectifs

Le projet Streaming Lab consiste à déployer une infrastructure complète de diffusion multimédia et de gestion d'identité sur un serveur physique dédié, dans le cadre du cursus B3 INFRA d'Ynov Campus.

**Objectifs :**
- Déployer une plateforme de streaming vidéo accessible depuis Internet
- Mettre en place une gestion centralisée des identités (SSO) et des secrets (Vault)
- Assurer la haute disponibilité des bases de données (Patroni HA)
- Assurer la supervision et l'observabilité de l'infrastructure
- Garantir la sécurité des données et des accès (Zero Trust, réseau isolé, CrowdSec)

---

## 2. Infrastructure physique

### Équipements réseau

| Équipement | Modèle | Rôle | IP |
|-----------|--------|------|----|
| Firewall | FortiGate 60F | Pare-feu, routage, VPN IPsec | 10.0.0.1 |
| Switch L2/L3 | Cisco 3650 48P (SW-01) | Trunk 802.1Q, VLANs | 192.168.90.10 |
| DNS physique | Raspberry Pi 3B+ (DNS-01) | Résolution DNS interne | 192.168.20.20 |

### Serveur Proxmox

| Composant | Valeur |
|-----------|--------|
| Modèle | Dell PowerEdge T140 (PROX-01) |
| Hyperviseur | Proxmox VE 8.x |
| Hostname | `quentin` |
| IP management | 192.168.90.50 |

### Machines virtuelles

| VM | Rôle | OS | IP | VLAN | RAM | vCPU |
|----|------|----|----|------|-----|------|
| vm-streaming | Services applicatifs (18 conteneurs Docker) | Debian 12 | 192.168.10.2 | VLAN 10 | 8 Go | 4 |
| vm-backup | Sauvegardes Veeam B&R | Debian 12 | 192.168.30.2 | VLAN 30 | 4 Go | 2 |

> **Note :** La résolution DNS interne est assurée par le Raspberry Pi 3B+ (DNS-01, 192.168.20.20, VLAN 20) — équipement physique dédié, pas une VM.

---

## 3. Architecture réseau

### Topologie physique

```
Internet
    │
    ▼
Cloudflare (DNS · TLS 1.3 · Tunnel sortant)
    │  Tunnel cloudflared (aucun port entrant ouvert)
    ▼
FortiGate 60F (10.0.0.1)  ← Firewall · ACLs · VPN IPsec
    │  Trunk 802.1Q
    ▼
Cisco 3650 48P (SW-01, 192.168.90.10)
    │
    ├── VLAN 10 (192.168.10.0/24)  → vm-streaming (services)
    ├── VLAN 20 (192.168.20.0/24)  → DNS-01 Raspberry Pi (192.168.20.20)
    ├── VLAN 30 (192.168.30.0/24)  → vm-backup (192.168.30.2) · Veeam Repository
    └── VLAN 90 (192.168.90.0/24)  → Management (Proxmox iDRAC, SW-01)
```

### VLANs

| VLAN | Réseau | Usage |
|------|--------|-------|
| 10 | 192.168.10.0/24 | vm-streaming — services applicatifs |
| 20 | 192.168.20.0/24 | DNS-01 Raspberry Pi (192.168.20.20) |
| 30 | 192.168.30.0/24 | vm-backup (192.168.30.2) — Veeam Repository |
| 90 | 192.168.90.0/24 | Management (Proxmox, iDRAC, switch) |

### Flux TLS

Cloudflare termine le TLS 1.3 côté public. Le tunnel cloudflared établit une connexion sortante vers Cloudflare — **aucun port entrant n'est ouvert sur le FortiGate**. Traefik reçoit le trafic en HTTP interne sur le port 80.

### Réseaux Docker (vm-streaming)

| Réseau | Mode | Usage |
|--------|------|-------|
| `streaming-public` | Bridge | Services exposés via Traefik (Jellyfin, Keycloak, MinIO, Vault, Grafana, TrivyHub) |
| `streaming-private` | Bridge **--internal** | Backend isolé : cluster Patroni HA (etcd, postgres-01/02, haproxy-postgres) |
| `streaming-monitoring` | Bridge | Stack d'observabilité (Prometheus, Loki, Grafana, Alertmanager, Promtail, cAdvisor, node-exporter, postgres-exporter) |

> Le réseau `streaming-private` est déclaré `--internal` : aucun accès Internet possible depuis ce réseau. Les nœuds PostgreSQL et etcd sont strictement isolés.

---

## 4. Architecture applicative

### Vue d'ensemble

```
                    ┌──────────────────────────────────────────────┐
                    │                vm-streaming                   │
                    │                                              │
  Cloudflare ──────►│  Traefik v3.3 :80                          │
  Tunnel            │     │                                        │
                    │     ├──► Jellyfin 10.10.7  :8096            │
                    │     ├──► Keycloak 24        :8080            │
                    │     ├──► Grafana            :3000            │
                    │     ├──► MinIO Console      :9001            │
                    │     ├──► Vault 1.17         :8200            │
                    │     └──► TrivyHub                            │
                    │                                              │
                    │  ┌─── streaming-private (--internal) ──────┐ │
                    │  │  etcd v3.5.17  (DCS Patroni)           │ │
                    │  │  haproxy-postgres :5000/:5001/:7000     │ │
                    │  │  postgres-01 ★ Leader  (PostgreSQL 17) │ │
                    │  │  postgres-02   Replica (streaming WAL)  │ │
                    │  └─────────────────────────────────────────┘ │
                    │                                              │
                    │  ┌─── streaming-monitoring ────────────────┐ │
                    │  │  Prometheus · Loki · Grafana            │ │
                    │  │  Alertmanager · Promtail · cAdvisor     │ │
                    │  │  node-exporter · postgres-exporter      │ │
                    │  └─────────────────────────────────────────┘ │
                    └──────────────────────────────────────────────┘
```

### Catalogue des services (18 conteneurs)

#### streaming-public

| Service | Image | Rôle | Port | Domaine |
|---------|-------|------|------|---------|
| Traefik | `traefik:v3.3` | Reverse proxy HTTP | 80 | `traefik.duoowatch.com` |
| Jellyfin | `jellyfin/jellyfin:10.10.7` | Streaming multimédia | 8096 | `jellyfin.duoowatch.com` |
| Keycloak | `quay.io/keycloak/keycloak:24` | SSO / IAM | 8080 | `keycloak.duoowatch.com` |
| MinIO | `minio/minio:latest` | Stockage objet S3 | 9000/9001 | `minio.duoowatch.com` |
| Vault | `hashicorp/vault:1.17` | Gestion des secrets | 8200 | `vault.duoowatch.com` |
| Grafana | `grafana/grafana:latest` | Tableaux de bord | 3000 | `grafana.duoowatch.com` |
| TrivyHub | — | Scan CVE images Docker | — | Interne |

#### streaming-private (--internal)

| Service | Image | Rôle | Port |
|---------|-------|------|------|
| etcd | `quay.io/coreos/etcd:v3.5.17` | DCS — consensus cluster Patroni | 2379 |
| haproxy-postgres | `haproxy:2.9-alpine` | Load balancer PostgreSQL | 5000/5001/7000 |
| postgres-01 | Patroni + PostgreSQL 17 | Nœud primaire (Leader) | 5432 |
| postgres-02 | Patroni + PostgreSQL 17 | Nœud secondaire (Replica) | 5432 |

#### streaming-monitoring

| Service | Image | Rôle | Port |
|---------|-------|------|------|
| Prometheus | `prom/prometheus:latest` | Collecte métriques (scrape 15s) | 9090 |
| Loki | `grafana/loki:latest` | Agrégation logs | 3100 |
| Grafana | `grafana/grafana:latest` | Dashboards + OIDC Keycloak | 3000 |
| Alertmanager | `prom/alertmanager:latest` | Gestion alertes | 9093 |
| Promtail | `grafana/promtail:latest` | Collecteur logs Docker + FortiGate | — |
| cAdvisor | `gcr.io/cadvisor/cadvisor` | Métriques par conteneur | 8080 |
| node-exporter | `prom/node-exporter:latest` | Métriques hôte VM | 9100 |
| postgres-exporter | `prometheuscommunity/postgres-exporter` | Métriques Patroni + PG | 9187 |

---

## 5. Haute disponibilité — Patroni HA Cluster

### Architecture

Le cluster PostgreSQL est géré par **Patroni** avec **etcd** comme DCS (Distributed Configuration Store) :

```
etcd (consensus)
    │
    ├── postgres-01 ★ Leader  ─── écritures R/W
    └── postgres-02   Replica ─── réplication streaming WAL (lag 0)
                          │
                    haproxy-postgres
                          ├── :5000 → Leader (R/W)  ← utilisé par Keycloak
                          ├── :5001 → Replica (R/O)
                          └── :7000 → Stats HAProxy
```

- **Failover automatique :** si postgres-01 tombe, Patroni promeut postgres-02 via consensus etcd
- **Reconnexion transparente :** haproxy-postgres redirige vers le nouveau Leader sans changement de configuration côté application
- **Keycloak** se connecte via `haproxy-postgres:5000` (toujours le Leader)

### Bases de données créées

| Base | Utilisateur | Rôle |
|------|-------------|------|
| `keycloak` | `keycloak` | Stockage IAM Keycloak |
| `postgres` (superuser) | `postgres` | Administration |

---

## 6. Stockage objet — MinIO

MinIO fournit un stockage compatible S3 pour :

| Bucket | Usage |
|--------|-------|
| `backups` | Sauvegardes Veeam et dumps système |
| `db-dumps` | Exports PostgreSQL quotidiens (cron) |
| `streaming-media` | Médias Jellyfin |

> **Note NoSQL :** Le projet n'utilise pas de base documentaire (MongoDB) ni de cache (Redis). Ce choix est délibéré : Keycloak et Jellyfin ne requièrent pas de NoSQL. MinIO assure le rôle de stockage non-relationnel via son API S3 (clé-valeur objet). Cette décision est documentée dans `docs/COMPARATIF_SOLUTIONS.md`.

---

## 7. Gestion des identités (IAM)

Keycloak assure le SSO pour tous les services :

- **Realm :** `streaming-lab`
- **Clients OIDC :** Jellyfin, Grafana, MinIO
- **Protocol :** OpenID Connect (OIDC) / OAuth 2.0 — Authorization Code Flow avec PKCE
- **Rôles :** `admin`, `viewer`, `media-user`

Les utilisateurs s'authentifient une seule fois sur Keycloak, le JWT est propagé aux services via OIDC.

---

## 8. Gestion des secrets — HashiCorp Vault

| Chemin | Contenu |
|--------|---------|
| `secret/databases` | Credentials PostgreSQL + mot de passe réplication |
| `secret/keycloak` | Admin + client secrets |
| `secret/minio` | Root user/password + client secret |
| `secret/grafana` | Admin + client secret Keycloak |
| `secret/trivyhub` | JWT secret |
| `secret/traefik` | Basic auth dashboard |

**Injection :** `scripts/vault-env.sh` lit tous les secrets depuis Vault et régénère le fichier `.env` à la racine du projet. Aucun secret ne transite dans les fichiers docker-compose.

**Unseal :** Vault démarre toujours scellé — 3 des 5 clés Shamir sont requises à chaque redémarrage.

---

## 9. Observabilité

```
Conteneurs / Système
        │
        ├── Promtail ──────────► Loki ──────────► Grafana (logs)
        ├── FortiGate syslog ──► Promtail
        │
        └── cAdvisor           ┐
            node-exporter      ├──► Prometheus ──► Grafana (métriques)
            postgres-exporter  │
            Alertmanager ◄─────┘
```

- **Métriques :** Prometheus scrape toutes les 15s — 18 cibles actives
- **Logs :** Promtail collecte les logs Docker et les syslog FortiGate
- **Alertes :** Alertmanager gère les notifications
- **Dashboards :** 3 dashboards Grafana provisionnés (infra-overview, logs-central, vm-detail)
- **Auth Grafana :** SSO Keycloak OIDC

---

## 10. Sécurité

### Modèle Zero Trust

| Couche | Mesure |
|--------|--------|
| Périmètre | Cloudflare Tunnel — zéro port entrant ouvert sur FortiGate |
| Transport | TLS 1.3 terminé chez Cloudflare |
| Réseau | VLANs FortiGate (10/20/90), streaming-private --internal |
| Identité | Keycloak SSO OIDC — authentification systématique |
| Secrets | HashiCorp Vault — aucun secret en clair dans le code |
| IDS | CrowdSec — analyse comportementale des logs Traefik/Keycloak/SSH |
| Images | TrivyHub — scan CVE de toutes les images Docker |
| Accès DB | Users dédiés par service, pas de superuser exposé |

### Isolation réseau

- `streaming-private --internal` : les nœuds PostgreSQL et etcd n'ont aucun accès Internet
- Les services exposés (Keycloak) atteignent la DB uniquement via haproxy-postgres
- Promtail n'a accès qu'en lecture seule au socket Docker

### IDS — CrowdSec

CrowdSec est déployé en mode **log analyser** : il analyse les logs produits par Traefik, Keycloak et SSH pour détecter des comportements suspects (brute-force, scan de ports, payloads connus). Ce choix remplace Suricata (DPI trop coûteux en CPU/stockage sur un Dell T140 partagé entre 18 services).

---

## 11. Sauvegarde et résilience

### Architecture 3-2-1

| Copie | Support | Outil |
|-------|---------|-------|
| 1 — locale | Volumes Docker (vm-streaming) | Docker volumes |
| 2 — vm-backup | Veeam Worker → vm-backup:/backup (192.168.30.2, VLAN 30) | Veeam B&R |
| 3 — objet | MinIO buckets (db-dumps, backups) | Scripts cron |

### RTO / RPO

| Indicateur | Objectif |
|-----------|---------|
| RTO | < 4 heures |
| RPO | < 24 heures |

### Planning des sauvegardes

| Tâche | Heure | Fréquence |
|-------|-------|-----------|
| Dump PostgreSQL → MinIO | 01h00 | Quotidien |
| Sauvegarde vm-streaming (incrémentale) | 02h00 | Quotidien |
| Sauvegarde vm-backup (complète) | 03h00 | Hebdomadaire |

Rétention : 7 jours / 4 semaines / 3 mois.

---

## 12. Déploiement et CI/CD

### GitFlow

```
main (production)
  └── develop (intégration)
        ├── feature/docker-stacks
        ├── feature/monitoring-ids
        ├── feature/backup
        ├── feature/ci
        └── feature/documentation
```

### GitHub Actions (feature/ci)

- Lint YAML (yamllint) — sur chaque PR
- Validation docker-compose (`docker compose config`) — sur chaque PR
- Déploiement automatique via SSH sur vm-streaming — sur push vers `main`

### Déploiement

```bash
docker compose --env-file .env -f docker/<stack>/docker-compose.yml up -d
```

> **Important :** toujours passer `--env-file .env` depuis la racine du repo — sans cela, les variables d'environnement ne sont pas résolues depuis le bon fichier.

### Makefile — commandes principales

| Commande | Action |
|----------|--------|
| `make up` | Démarre tous les stacks |
| `make down` | Arrête tous les stacks |
| `make ps` | État de tous les conteneurs |
| `make logs-keycloak` | Logs Keycloak en temps réel |

---

## 13. Domaine et DNS

- **Domaine public :** `duoowatch.com` (géré par Cloudflare)
- **Enregistrements :** CNAMEs pointant vers le tunnel Cloudflare
- **Tunnel :** `cloudflared` sur vm-streaming — connexion sortante uniquement
- **DNS interne :** Raspberry Pi 3B+ (DNS-01, 192.168.20.20) pour la résolution `*.streaminglab.local`

Aucun port entrant n'est ouvert sur le FortiGate — tout le trafic entrant passe par le tunnel Cloudflare.
