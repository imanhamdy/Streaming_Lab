# Procédure de test de restauration

## 1. Restauration PostgreSQL depuis dump MinIO

### Télécharger le dernier dump

```bash
source /home/principal/streaming-lab/.env

docker run --rm \
  --network streaming-net \
  -v /tmp/restore-test:/restore \
  -e MINIO_ROOT_USER="$MINIO_ROOT_USER" \
  -e MINIO_ROOT_PASSWORD="$MINIO_ROOT_PASSWORD" \
  minio/mc:latest \
  sh -c "mc alias set minio http://minio:9000 \"\$MINIO_ROOT_USER\" \"\$MINIO_ROOT_PASSWORD\" && \
         mc ls minio/db-dumps && \
         mc cp \$(mc ls minio/db-dumps | awk 'END{print \$NF}') /restore/"
```

### Tester la lisibilité

```bash
bash scripts/tests/test_pgsql_dump_restore.sh
```

### Restauration dans un container temporaire

```bash
source /home/principal/streaming-lab/.env

docker run --rm \
  --name postgres-restore-test \
  --network db-net \
  -e POSTGRES_PASSWORD=testonly \
  -v /tmp/restore-test:/dumps \
  -d postgres:17-alpine

sleep 5

gunzip -c /tmp/restore-test/*.sql.gz | \
  docker exec -i postgres-restore-test psql -U postgres

docker stop postgres-restore-test
echo "Restore test: OK"
```

---

## 2. Restauration VM complète via Veeam (mensuel)

### Procédure

1. Ouvrir la console Veeam Backup & Replication
2. Sélectionner le job `vm-streaming-production`
3. Choisir le point de restauration le plus récent
4. Lancer **Restore entire VM** → renommer en `vm-streaming-test`
5. Démarrer sur un réseau isolé (ne pas connecter au réseau de production)
6. Valider :
   - Boot complet
   - `docker ps` → tous les containers démarrés
   - Jellyfin accessible sur port 8096
   - Keycloak accessible sur port 8081
   - Grafana accessible sur port 3000
7. Supprimer `vm-streaming-test` après validation

### Rapport de test

Documenter dans `docs/RESTORE_TEST_LOG.md` :
- Date du test
- Point de restauration utilisé
- Durée de restauration
- Services validés
- PASS / FAIL

---

## 3. Validation des routes (post-restore)

```bash
bash scripts/tests/test_routes.sh
```

---

## Fréquence recommandée

| Type | Fréquence |
|---|---|
| Test de lisibilité dump | Automatique après chaque backup |
| Restauration PostgreSQL temporaire | Mensuel |
| Restauration VM complète Veeam | Mensuel |
