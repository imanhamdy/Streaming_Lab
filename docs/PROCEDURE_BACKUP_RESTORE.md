# Procédure de Sauvegarde et Test de Restauration
**Streaming Lab - Ynov Campus B3 INFRA**
Version 1.0 - Juin 2026

---

## 1. Objectif

Ce document décrit la procédure de sauvegarde automatisée des VMs Proxmox ainsi que le protocole de test de restauration mensuel. Il constitue la preuve opérationnelle du Plan de Continuité d'Activité (PCA) défini dans `docs/PCA_PRA.docx`.

**Objectifs de récupération :**
| Indicateur | Cible |
|---|---|
| RPO (Recovery Point Objective) | 24 heures |
| RTO (Recovery Time Objective) | 4 heures |
| Fréquence des tests de restauration | Mensuelle |

---

## 2. Architecture de sauvegarde

```
vm-streaming (192.168.20.10)  ─┐
vm-dns       (192.168.110.101) ─┼──► Veeam B&R ──► vm-backup (192.168.140.10)
vm-backup    (192.168.140.10)  ─┘         │
                                           └──► Stockage local /backup (chiffré AES-256)
```

- **Outil :** Veeam Backup & Replication sur `vm-backup`
- **Chiffrement :** AES-256 sur le canal réseau (VLAN 140 dédié)
- **Rétention :**
  - Quotidienne : 7 jours
  - Hebdomadaire : 4 semaines
  - Mensuelle : 3 mois

---

## 3. Procédure de sauvegarde automatisée

### 3.1 Planning des sauvegardes

| VM | Heure | Fréquence | Type |
|---|---|---|---|
| vm-streaming | 02h00 | Quotidienne | Incrémentale |
| vm-dns | 02h30 | Quotidienne | Incrémentale |
| vm-backup (config) | 03h00 | Hebdomadaire | Complète |

### 3.2 Vérification du statut des sauvegardes

Connexion à Veeam B&R sur `vm-backup` :
```bash
ssh principal@192.168.140.10
# Vérifier le journal des jobs Veeam
sudo veeamconfig job list
sudo veeamconfig session list --jobName "Backup_vm-streaming"
```

Résultat attendu : `Status: Success` pour chaque job.

---

## 4. Procédure de test de restauration mensuel

### Pré-requis
- [ ] VPN FortiClient actif
- [ ] Accès SSH à Proxmox (192.168.90.50)
- [ ] Accès Veeam B&R sur vm-backup
- [ ] Créneau de maintenance annoncé à l'équipe (hors heures de production)

---

### Étape 1 - Identifier le point de restauration

Sur `vm-backup`, lister les points de restauration disponibles :
```bash
sudo veeamconfig point list --jobName "Backup_vm-streaming"
```

Exemple de sortie :
```
ID                                   CreationTime          Type
----                                 ------------          ----
a1b2c3d4-...                         2026-06-22 02:00:01   Increment
e5f6g7h8-...                         2026-06-15 02:00:01   Full
```

Sélectionner le point de restauration J-1 (dernier incrémental).

---

### Étape 2 - Restauration en environnement isolé

> **Important :** Ne jamais restaurer par-dessus la VM de production. Toujours restaurer dans un environnement de test isolé.

Sur Proxmox (192.168.90.50), créer une VM de test temporaire :

```bash
# Via l'interface Proxmox ou CLI
qm clone <vmid_vm-streaming> <new_vmid> --name vm-streaming-test --full
```

Lancer la restauration via Veeam vers la VM de test :
```bash
sudo veeamconfig restore vm \
  --pointId a1b2c3d4-... \
  --vmName vm-streaming-test \
  --server 192.168.90.50
```

---

### Étape 3 - Vérification post-restauration

Une fois la VM restaurée et démarrée, vérifier :

```bash
ssh principal@<ip_vm_test>

# 1. Vérifier que les containers Docker sont actifs
docker ps

# Résultat attendu : tous les containers en status "Up"
# traefik, jellyfin, keycloak, vault, prometheus, grafana, loki, minio

# 2. Vérifier l'accès aux bases de données
docker exec postgres pg_isready -U streaminglab
docker exec redis redis-cli ping

# 3. Vérifier l'intégrité des données
docker exec postgres psql -U streaminglab -c "SELECT COUNT(*) FROM information_schema.tables;"

# 4. Vérifier les volumes MinIO
docker exec minio mc ready local
```

**Critères de succès :**
- [ ] Tous les containers démarrent sans erreur
- [ ] `pg_isready` retourne `accepting connections`
- [ ] `redis-cli ping` retourne `PONG`
- [ ] MinIO répond `The cluster is ready`
- [ ] Interface Grafana accessible sur port 3000
- [ ] Jellyfin accessible sur port 8096

---

### Étape 4 - Rapport de test

Compléter le tableau de suivi ci-dessous après chaque test :

| Date | Point restauré | VM testée | Durée restauration | Résultat | Anomalies | Validé par |
|---|---|---|---|---|---|---|
| 2026-06-22 | 2026-06-21 02:00 | vm-streaming-test | 47 min | ✅ Succès | Aucune | Iman H. |
| | | | | | | |
| | | | | | | |

---

### Étape 5 - Nettoyage

Après validation, supprimer la VM de test :
```bash
# Arrêter et supprimer la VM de test sur Proxmox
qm stop <new_vmid>
qm destroy <new_vmid>
```

---

## 5. Procédure de restauration d'urgence (sinistre réel)

En cas de défaillance réelle d'une VM de production :

1. **Évaluer l'impact** - identifier la VM affectée et les services impactés
2. **Notifier l'équipe** - informer tous les membres via le canal d'urgence
3. **Isoler** - désactiver les accès réseau vers la VM défaillante (règle FortiGate)
4. **Restaurer** - suivre les étapes 1 à 3 ci-dessus, mais vers la VM de production
5. **Valider** - exécuter les vérifications de l'étape 3
6. **Rétablir** - réactiver les accès réseau
7. **Post-mortem** - documenter l'incident dans `docs/` sous `INCIDENT_YYYY-MM-DD.md`

**RTO cible : 4 heures** à partir du déclenchement de la restauration.

---

## 6. Contacts d'urgence

| Rôle | Nom | Responsabilité |
|---|---|---|
| Admin système DevOps | Iman Hamdy | Docker, automatisation, BDD |
| Admin réseau | Quentin | FortiGate, accès réseau |
| Admin monitoring | Adrien | Suricata, détection incident |
