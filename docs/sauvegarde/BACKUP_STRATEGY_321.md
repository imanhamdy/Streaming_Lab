# Backup Strategy — Règle 3-2-1

## Vue d'ensemble

Stratégie 3-2-1 :
- **3 copies** : production + backup Veeam (VM-level) + dumps applicatifs MinIO
- **2 supports** : stockage Proxmox/VM + stockage objet MinIO
- **1 copie isolée/offsite recommandée** : réplication future vers S3 externe

Veeam protège la VM complète.
MinIO stocke les sauvegardes logiques : pg_dump, exports de configuration, données applicatives.

---

## Architecture cible

```
PROXMOX HOST
│
├── vm-streaming          → Production (Keycloak, Jellyfin, MinIO, Grafana)
│     ├── pg_dump daily   → MinIO bucket: db-dumps
│     └── config export   → MinIO bucket: backups
│
├── Veeam Backup Server   → Orchestration / gestion des jobs
├── Veeam Worker          → Traitement des données de sauvegarde Proxmox
│
└── vm-backup
      └── /backup         → Dépôt Linux (repository Veeam)
```

---

## Composants

| Composant | Rôle | Fréquence |
|---|---|---|
| Veeam B&R | Sauvegarde VM complète (vm-streaming) | Incrémentale daily 02:00, Full Sunday 01:00 |
| pg_dump → MinIO | Dump logique PostgreSQL | Daily 02:30 |
| Config export → MinIO | Configs Docker + scripts | Weekly Sunday 02:45 |
| Restore test | Restauration vm-streaming-test | Mensuel |

---

## Politique de rétention

- Veeam : 30 jours
- MinIO db-dumps : nettoyage manuel ou lifecycle policy à configurer
- MinIO backups : nettoyage manuel ou lifecycle policy à configurer

---

## Futur : réplication offsite

Objectif : répliquer le bucket MinIO `db-dumps` vers un S3 externe (ex: Backblaze B2, Scaleway Object Storage) pour disposer d'une copie géographiquement séparée.

---

## PostgreSQL HA (étape suivante)

Cible documentée — ne pas implémenter avant que la sauvegarde soit validée :

```
Patroni + etcd + HAProxy
  ├── postgres-primary
  └── postgres-replica (automatic failover)
```

Implémenter sous `docker/databases/ha/` séparément du stack actuel.
