# DAT Streaming Lab — Section 5 : Stratégie Stockage et Bases de Données
**Streaming Lab — Ynov Campus B3 INFRA**
Version 1.0 — Juin 2026

---

## 5. Stockage et Bases de Données

### 5.1 Vue d'ensemble

Le Streaming Lab exploite quatre moteurs de persistance couvrant des besoins complémentaires :

| Service | Moteur | Role | Port |
|---|---|---|---|
| `postgres` | PostgreSQL 17-alpine | Base relationnelle (Keycloak, applications) | 5432 |
| `mongodb` | MongoDB 8.0.10 | Base documentaire (métadonnées médias) | 27017 |
| `redis` | Redis 7-alpine | Cache en mémoire, sessions, files de tâches | 6379 |
| `minio` | MinIO RELEASE.2025-06-13 | Stockage objet S3-compatible (fichiers médias, backups) | 9000 / 9001 |

Tous les services s'exécutent dans le réseau Docker interne `db-net` (VLAN 20), sans exposition directe à Internet. Les credentials sont gérés exclusivement par **HashiCorp Vault** et injectés au démarrage via `scripts/vault-env.sh`.

---

### 5.2 Architecture des volumes

Chaque service dispose de volumes Docker nommés persistants, définis dans `docker/databases/docker-compose.yml` :

```
postgres_data    -> /var/lib/postgresql/data
mongodb_data     -> /data/db
redis_data       -> /data
minio_data       -> /data
```

Les volumes sont stockés sur `vm-streaming` dans `/var/lib/docker/volumes/`. Ils sont inclus dans les sauvegardes Veeam B&R (snapshot VM complet — voir `docs/PROCEDURE_BACKUP_RESTORE.md`).

---

### 5.3 Stratégie de sauvegarde 3-2-1

La stratégie **3-2-1** garantit la résilience des données :

| Règle | Description | Mise en oeuvre |
|---|---|---|
| **3** copies des données | 3 exemplaires distincts | Données actives (VM) + snapshot Veeam J-1 + archive mensuelle |
| **2** supports différents | 2 types de media | Disque NVMe `vm-streaming` + stockage HDD `vm-backup` (VLAN 140) |
| **1** copie hors site | 1 exemplaire délocalisé | Export mensuel chiffré AES-256 vers `vm-backup` sur VLAN dédié isolé |

#### 5.3.1 PostgreSQL

| Paramètre | Valeur |
|---|---|
| Version | 17-alpine |
| Sauvegarde logique | `pg_dump` quotidien via cron (J-7 rétention) |
| Sauvegarde physique | Snapshot VM Veeam (inclut volume `postgres_data`) |
| Chiffrement repos | AES-256 via Veeam |
| Chiffrement transit | TLS sur réseau VLAN 140 |
| RPO | 24 heures |
| RTO | 2 heures (restauration `pg_restore` + validation) |

Commande de sauvegarde logique :
```bash
docker exec postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB \
  | gzip > /backup/postgres_$(date +%Y%m%d).sql.gz
```

Vérification de l'intégrité :
```bash
docker exec postgres pg_isready -U $POSTGRES_USER
```

#### 5.3.2 MongoDB

| Paramètre | Valeur |
|---|---|
| Version | 8.0.10 |
| Sauvegarde logique | `mongodump` quotidien (archive BSON compressée) |
| Sauvegarde physique | Snapshot VM Veeam (inclut volume `mongodb_data`) |
| Chiffrement repos | AES-256 via Veeam |
| RPO | 24 heures |
| RTO | 2 heures (restauration `mongorestore`) |

Commande de sauvegarde :
```bash
docker exec mongodb mongodump \
  --username $MONGO_INITDB_ROOT_USERNAME \
  --password $MONGO_INITDB_ROOT_PASSWORD \
  --authenticationDatabase admin \
  --archive=/backup/mongo_$(date +%Y%m%d).archive \
  --gzip
```

#### 5.3.3 Redis

Redis est utilisé comme **cache et gestionnaire de sessions** — les données sont par nature éphémères. La stratégie de sauvegarde est allégée en conséquence :

| Paramètre | Valeur |
|---|---|
| Version | 7-alpine |
| Persistance | RDB (snapshot toutes les 300s si >= 10 changements) |
| Sauvegarde | Snapshot VM Veeam uniquement (pas de dump logique dédié) |
| RPO | Tolérance à la perte du cache (reconstruction automatique) |
| RTO | < 30 minutes (redémarrage container, rechauffe du cache) |

En cas de perte totale, le cache se reconstruit automatiquement à la prochaine sollicitation applicative. Aucune donnée critique n'est stockée exclusivement dans Redis.

#### 5.3.4 MinIO

MinIO héberge les **fichiers médias** (bibliothèque Jellyfin) et les **exports de sauvegarde** des autres services.

| Paramètre | Valeur |
|---|---|
| Version | RELEASE.2025-06-13T11-33-47Z |
| Mode | Single-node, single-drive (environnement lab) |
| Buckets principaux | `media`, `backups`, `thumbnails` |
| Sauvegarde | Snapshot VM Veeam + réplication bucket `backups` vers `vm-backup` |
| Chiffrement repos | SSE-S3 (chiffrement côté serveur MinIO) |
| RPO | 24 heures |
| RTO | 4 heures (restauration snapshot + vérification intégrité buckets) |

Vérification de disponibilité :
```bash
docker exec minio mc ready local
```

---

### 5.4 Sécurité des accès

| Service | Authentification | Stockage des credentials |
|---|---|---|
| PostgreSQL | Utilisateur dédié `streaminglab`, mot de passe fort | HashiCorp Vault `secret/databases/postgres_password` |
| MongoDB | Authentification SCRAM-SHA-256, user root isolé | HashiCorp Vault `secret/databases/mongo_password` |
| Redis | `requirepass` activé | HashiCorp Vault `secret/databases/redis_password` |
| MinIO | Access key / Secret key | HashiCorp Vault `secret/minio/root_password` |

Aucun credential n'est stocké en clair dans les fichiers de configuration. Le fichier `docker/.env` est généré dynamiquement à chaque déploiement par `scripts/vault-env.sh` et n'est pas versionné (présent dans `.gitignore`).

---

### 5.5 Supervision

Les métriques des bases de données sont collectées par **Prometheus** et visualisées dans **Grafana** :

| Service | Exporter | Métriques clés |
|---|---|---|
| PostgreSQL | `postgres_exporter` (port 9187) | Connexions actives, transactions/s, taille BDD, locks |
| MongoDB | `mongodb_exporter` (port 9216) | Opérations/s, connexions, mémoire WiredTiger |
| Redis | Métriques natives via `redis-cli INFO` | `used_memory`, `connected_clients`, `keyspace_hits` |
| MinIO | Console MinIO (port 9001) + métriques Prometheus natives | Espace utilisé, requêtes/s, erreurs |

Alertes configurées dans Alertmanager :
- Espace disque volumes > 80% → alerte WARNING
- Connexions PostgreSQL > 90% du `max_connections` → alerte CRITICAL
- Service non disponible (`up == 0`) depuis > 2 minutes → alerte CRITICAL

---

### 5.6 Réseau et isolation

Tous les services de base de données sont isolés dans le réseau Docker `db-net`, correspondant au **VLAN 20** de la segmentation réseau (voir `docs/NETWORKS.md`).

```
VLAN 20 (db-net)
  192.168.20.x
       |
  +---------+---------+---------+
  |         |         |         |
postgres  mongodb   redis     minio
 :5432     :27017    :6379   :9000/:9001
```

Seuls les services applicatifs sur `streaming-net` peuvent joindre `db-net` via les règles FortiGate. Aucun accès direct depuis Internet ou le réseau administration (VLAN 90).

---

### 5.7 Versions et conformité CVE

Les versions déployées ont été sélectionnées en réponse aux CVE critiques/hauts identifiés par TrivyHub (scans Trivy CI/CD) :

| Service | Version precedente | Version actuelle | Raison de la mise a jour |
|---|---|---|---|
| PostgreSQL | 15-alpine | **17-alpine** | Correction CVE critiques sur pg15 |
| MongoDB | 4.4 | **8.0.10** | EOL mongo 4.4, multiples CVE |
| MinIO | latest (non fixe) | **RELEASE.2025-06-13** | Pin de version + correctifs securite |
| Redis | 7-alpine | **7-alpine** | Version maintenue, pas de changement |

Les versions sont fixees dans `docker/databases/docker-compose.yml` et maintenues a jour via `scripts/update-images.sh` apres chaque cycle de scan TrivyHub.
