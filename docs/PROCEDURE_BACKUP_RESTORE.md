# Procédure de Sauvegarde et Test de Restauration
**Streaming Lab - Ynov Campus B3 INFRA**
Version 2.0 - Juillet 2026

---

## 1. Objectif

Ce document décrit la stratégie 3-2-1 implémentée pour le Streaming Lab, combinant :
- **Veeam B&R** : sauvegarde VM-level de `vm-streaming` vers `vm-backup`
- **pg_dump → MinIO** : dump logique PostgreSQL quotidien
- **Config export → MinIO** : archivage hebdomadaire des configurations Docker/scripts

**Objectifs de récupération :**
| Indicateur | Cible |
|---|---|
| RPO (Recovery Point Objective) | 24 heures |
| RTO (Recovery Time Objective) | 4 heures |
| Fréquence des tests de restauration | Mensuelle |

---

## 2. Architecture de sauvegarde (Règle 3-2-1)

```
PROXMOX HOST
│
├── vm-streaming (192.168.20.10)
│     ├── Production : Keycloak, Jellyfin, MinIO, Grafana, Vault
│     ├── pg_dump daily 02:30  ──────────────────────────────────► MinIO bucket: db-dumps
│     └── config export Sunday 02:45 ──────────────────────────► MinIO bucket: backups
│
├── Veeam Backup Server / Appliance
│     ├── Orchestration des jobs
│     └── Proxmox plug-in + Worker
│
└── vm-backup (192.168.140.10)
      └── /backup  ◄── Veeam incremental daily 02:00, full Sunday 01:00
```

**3 copies :** production + Veeam VM-level + dumps applicatifs MinIO
**2 supports :** stockage Proxmox/VM + stockage objet MinIO
**1 copie isolée :** réplication future vers S3 externe (Backblaze B2 / Scaleway)

---

## 3. Sauvegardes automatisées

### 3.1 Planning

| Composant | Script / Outil | Heure | Fréquence | Destination |
|---|---|---|---|---|
| VM complète vm-streaming | Veeam incrémental | 02:00 | Quotidienne | vm-backup:/backup |
| VM complète vm-streaming | Veeam full | 01:00 | Dimanche | vm-backup:/backup |
| PostgreSQL pg_dumpall | `backup_pgsql_to_minio.sh` | 02:30 | Quotidienne | MinIO: db-dumps |
| Configs Docker/scripts | `backup_configs_to_minio.sh` | 02:45 | Dimanche | MinIO: backups |
| Nettoyage dumps anciens | `cleanup_old_dumps.sh` | 03:00 | Dimanche | MinIO: db-dumps |

### 3.2 Cron installé sur vm-streaming

```cron
30 2 * * * /home/principal/streaming-lab/scripts/backup/backup_pgsql_to_minio.sh >> /var/log/streaming-lab-pg-backup.log 2>&1
45 2 * * 0 /home/principal/streaming-lab/scripts/backup/backup_configs_to_minio.sh >> /var/log/streaming-lab-config-backup.log 2>&1
0  3 * * 0 /home/principal/streaming-lab/scripts/backup/cleanup_old_dumps.sh >> /var/log/streaming-lab-cleanup.log 2>&1
```

Vérifier les logs :
```bash
tail -f /var/log/streaming-lab-pg-backup.log
tail -f /var/log/streaming-lab-config-backup.log
```

### 3.3 Exécution manuelle

```bash
# Régénérer .env depuis Vault
VAULT_TOKEN=<token> bash scripts/vault-env.sh

# Dump PostgreSQL
bash scripts/backup/backup_pgsql_to_minio.sh

# Export configuration
bash scripts/backup/backup_configs_to_minio.sh
```

### 3.4 Veeam — vérification statut

```bash
ssh principal@192.168.140.10
sudo veeamconfig job list
sudo veeamconfig session list --jobName "Backup_vm-streaming"
```

Résultat attendu : `Status: Success` pour chaque job.

---

## 4. Tests de validation — Suite automatisée

La suite de tests est dans `scripts/tests/`. Lancer tous les tests :

```bash
bash scripts/tests/test_all.sh
```

Sortie attendue :
```
========================================
 Streaming Lab — Full Test Suite
========================================

01 Containers         [PASS]
02 Networks           [PASS]
03 Routes             [PASS]
04 Volumes            [PASS]
05 MinIO buckets      [PASS]
06 PG Backup          [PASS]
07 PG Restore         [PASS]
08 Monitoring         [PASS]
09 SSO                [PASS]
10 Vault              [PASS]
11 Backup repo        [PASS]

========================================
 OVERALL: 11/11 PASS
========================================
```

Tests disponibles individuellement :

| Script | Valide |
|---|---|
| `test_containers.sh` | Tous les containers en cours d'exécution |
| `test_network.sh` | Routage interne et exposition bloquée |
| `test_routes.sh` | Routes HTTP par domaine via Traefik |
| `test_volumes.sh` | Volumes Docker et mount rclone |
| `test_minio_buckets.sh` | Création/vérification des buckets requis |
| `test_pgsql_backup.sh` | Backup end-to-end + upload MinIO |
| `test_pgsql_restore.sh` | Restauration dans container temporaire + validation |
| `test_monitoring.sh` | Prometheus, Grafana, Loki, Alertmanager |
| `test_sso.sh` | Keycloak OIDC discovery, MinIO SSO redirect |
| `test_vault.sh` | Vault initialisé, descellé, secrets lisibles |
| `test_backup_repository.sh` | SSH vm-backup, /backup, espace disque |

---

## 5. Test de restauration mensuel (Veeam)

### Pré-requis
- [ ] Accès SSH à Proxmox (192.168.90.50)
- [ ] Accès Veeam B&R
- [ ] Créneau de maintenance annoncé à l'équipe

### Étape 1 — Identifier le point de restauration

```bash
sudo veeamconfig point list --jobName "Backup_vm-streaming"
```

### Étape 2 — Restauration en environnement isolé

> **Important :** Ne jamais restaurer par-dessus la VM de production.

```bash
sudo veeamconfig restore vm \
  --pointId <id> \
  --vmName vm-streaming-test \
  --server 192.168.90.50
```

### Étape 3 — Vérification post-restauration

```bash
ssh principal@<ip_vm_test>

# Containers
docker ps

# Suite de tests complète
bash /home/principal/streaming-lab/scripts/tests/test_all.sh

# Vérification base de données
docker exec postgres pg_isready -U streaminglab

# MinIO
docker exec minio mc ready local
```

**Critères de succès :**
- [ ] Tous les containers démarrent sans erreur
- [ ] `test_all.sh` : tous les tests PASS
- [ ] `pg_isready` retourne `accepting connections`
- [ ] MinIO répond `The cluster is ready`
- [ ] Grafana accessible sur port 3000
- [ ] Jellyfin accessible sur port 8096
- [ ] MinIO SSO : `loginStrategy=redirect`

### Étape 4 — Rapport de test

| Date | Point restauré | Durée restauration | test_all.sh | Anomalies | Validé par |
|---|---|---|---|---|---|
| 2026-06-22 | 2026-06-21 02:00 | 47 min | — | Aucune | Iman H. |
| | | | | | |

### Étape 5 — Nettoyage

```bash
qm stop <new_vmid>
qm destroy <new_vmid>
```

---

## 6. Restauration PostgreSQL depuis dump MinIO

```bash
source /home/principal/streaming-lab/.env

# Lister les dumps disponibles
docker run --rm --network streaming-net \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && mc ls minio/db-dumps"

# Exécuter le test de restauration automatisé
bash scripts/tests/test_pgsql_restore.sh
```

Voir [POSTGRESQL_BACKUP.md](POSTGRESQL_BACKUP.md) pour la procédure complète.

---

## 7. Procédure de restauration d'urgence (sinistre réel)

1. **Évaluer l'impact** — identifier la VM affectée et les services impactés
2. **Notifier l'équipe** — informer tous les membres via le canal d'urgence
3. **Isoler** — désactiver les accès réseau vers la VM défaillante
4. **Restaurer** — Veeam restore vers production OU restauration PostgreSQL depuis MinIO selon la nature du sinistre
5. **Valider** — `bash scripts/tests/test_all.sh`
6. **Rétablir** — réactiver les accès réseau
7. **Post-mortem** — documenter dans `docs/INCIDENT_YYYY-MM-DD.md`

**RTO cible : 4 heures** à partir du déclenchement de la restauration.

---

## 8. Rétention

| Type | Rétention |
|---|---|
| Veeam incrémental | 30 jours |
| Veeam full | 4 semaines |
| MinIO db-dumps | 30 jours (cleanup_old_dumps.sh) |
| MinIO backups (configs) | Manuel |

---

## 9. Contacts d'urgence

| Rôle | Nom | Responsabilité |
|---|---|---|
| Admin système DevOps | Iman Hamdy | Docker, automatisation, BDD |
| Admin réseau | Quentin | FortiGate, accès réseau |
| Admin monitoring | Adrien | Suricata, détection incident |
