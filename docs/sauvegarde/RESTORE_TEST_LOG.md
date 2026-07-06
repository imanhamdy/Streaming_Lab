# Journal des tests de restauration
**Streaming Lab — Ynov Campus B3 INFRA**

---

## Test #001 — 2026-07-06

| Champ | Valeur |
|-------|--------|
| **Date** | 2026-07-06 |
| **Heure** | 07:35 – 07:40 UTC |
| **Opérateur** | Iman Hamdy |
| **Type de test** | Restauration PostgreSQL depuis dump MinIO |
| **Résultat global** | ✅ PASS |

### Contexte

Premier test de restauration opérationnel post-déploiement du cluster Patroni HA.
Dump produit par `scripts/backup/backup_pgsql_to_minio.sh` via `pg_dumpall` sur haproxy-postgres:5000 (Leader postgres-01).

### Étapes exécutées

| # | Étape | Durée | Résultat |
|---|-------|-------|----------|
| 1 | Dump PostgreSQL via haproxy-postgres:5000 → fichier `.sql` | ~2s | ✅ OK |
| 2 | Compression gzip → `postgres_all_2026-07-06_07-35-11.sql.gz` (62 Ko) | <1s | ✅ OK |
| 3 | Upload vers MinIO bucket `db-dumps` | <1s (8,32 MiB/s) | ✅ OK |
| 4 | Téléchargement depuis MinIO vers `/tmp/restore-test/` | <1s (14,16 MiB/s) | ✅ OK |
| 5 | Décompression → `postgres_all_2026-07-06_07-35-11.sql` (327 Ko) | <1s | ✅ OK |
| 6 | Lancement conteneur PostgreSQL 17 isolé (`postgres-restore-test`) | ~6s | ✅ OK |
| 7 | Restauration du dump (`psql -f`) | <2s | ✅ OK — exit code 0 |
| 8 | Validation bases présentes (`\l`) | — | ✅ `keycloak`, `postgres` présentes |
| 9 | Validation schéma Keycloak (`\dt`) | — | ✅ 17+ tables restaurées |
| 10 | Arrêt conteneur temporaire + nettoyage | <1s | ✅ OK |

### Validation détaillée

**Bases de données restaurées :**
```
keycloak  | Owner: streaminglab | Encoding: UTF8
postgres  | Owner: postgres
```

**Permissions vérifiées :**
- `keycloak` user a accès CONNECT + TEMP sur la base `keycloak` ✅
- Privilèges `streaminglab` (superuser réplication) correctement restaurés ✅

**Tables Keycloak présentes (extrait) :**
`admin_event_entity`, `authentication_execution`, `authentication_flow`,
`client`, `client_attributes`, `client_scope`, `client_session`, …

**Durée totale :** ~3 minutes (dump → upload → download → restore → validation)

### Points de restauration disponibles

| Bucket | Fichier | Taille | Date |
|--------|---------|--------|------|
| `db-dumps` | `postgres_all_2026-07-06_07-35-11.sql.gz` | 62 Ko | 2026-07-06 07:35 |
| `backups` | `streaming-lab-configs-2026-07-06_07-35-27.tar.gz` | 78 Ko | 2026-07-06 07:35 |

### Conclusion

La stratégie de sauvegarde PostgreSQL → MinIO est **opérationnelle**. Le dump logique `pg_dumpall` via le cluster Patroni HA est cohérent et restaurable dans un environnement isolé. Les données Keycloak (realm, clients OIDC, utilisateurs) sont intégralement récupérables.

**Prochains tests planifiés :**
- Test restauration configs (`backups` bucket) — à programmer
- Test restauration VM Veeam — dès que le job Veeam est configuré sur vm-backup

---

## Modèle pour tests futurs

```
## Test #00X — YYYY-MM-DD

| Champ | Valeur |
|-------|--------|
| Date | |
| Opérateur | |
| Type de test | |
| Point de restauration | |
| Résultat global | ✅ PASS / ❌ FAIL |

### Étapes
| # | Étape | Durée | Résultat |
...

### Observations
...
```
