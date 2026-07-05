# PostgreSQL Backup — pg_dump vers MinIO

## Script

`scripts/backup/backup_pgsql_to_minio.sh`

### Ce que fait le script

1. Lit les credentials depuis `.env`
2. Lance `pg_dumpall` dans le container `postgres`
3. Compresse le dump (gzip)
4. Upload vers MinIO bucket `db-dumps` via `minio/mc`
5. Supprime le fichier temporaire local

### Exécution manuelle

```bash
VAULT_TOKEN=<token> bash scripts/vault-env.sh   # régénère .env depuis Vault
bash scripts/backup/backup_pgsql_to_minio.sh
```

### Cron (vm-streaming)

```cron
30 2 * * * /home/principal/streaming-lab/scripts/backup/backup_pgsql_to_minio.sh >> /var/log/streaming-lab-pg-backup.log 2>&1
```

Vérifier les logs :
```bash
tail -f /var/log/streaming-lab-pg-backup.log
```

---

## Test de lisibilité du dump

```bash
bash scripts/tests/test_pgsql_dump_restore.sh
```

Vérifie que le dernier dump local est lisible (gunzip + head).

---

## Restauration complète (procédure)

Voir [RESTORE_TEST_PROCEDURE.md](RESTORE_TEST_PROCEDURE.md).

---

## Buckets MinIO requis

| Bucket | Contenu |
|---|---|
| `db-dumps` | Dumps PostgreSQL quotidiens |
| `backups` | Archives de configuration hebdomadaires |
| `streaming-media` | Médias Jellyfin (via rclone) |

Initialiser les buckets :
```bash
bash scripts/tests/test_minio_buckets.sh
```
