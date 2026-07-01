# Plan de Continuité d'Activité / Plan de Reprise d'Activité
**Streaming Lab — Ynov Campus B3 INFRA**
Compétence 3.17 — BC03
Version 1.0 — Juillet 2026

---

## Compétence visée

> **3.17** — Déployer des moyens de protections matériels et logiciels pour assurer la disponibilité des données et des applicatifs conformément au plan de continuité établi par la direction de l'entreprise.
>
> **Critère d'évaluation :** Les données répliquées sont disponibles et opérationnelles.

---

## 1. Objectif

Ce document définit :
- Le **PCA** (Plan de Continuité d'Activité) : comment maintenir un service minimal en cas d'incident
- Le **PRA** (Plan de Reprise d'Activité) : comment restaurer le service complet après un sinistre

Il s'appuie sur le BIA (`docs/BIA.md`) pour les priorités de reprise et sur `docs/PROCEDURE_BACKUP_RESTORE.md` pour les procédures opérationnelles.

---

## 2. Périmètre

| Élément | Détail |
|---|---|
| Serveur physique | DELL T140 — Proxmox VE 8 |
| VMs couvertes | vm-streaming, vm-dns, vm-backup |
| Services critiques | Traefik, Keycloak, PostgreSQL, Jellyfin |
| Services secondaires | MinIO, Redis, Vault, MongoDB, Grafana, Loki, Prometheus, Suricata |

---

## 3. Objectifs de récupération

| Indicateur | Cible |
|---|---|
| **RPO** (Recovery Point Objective) | **24 heures** — perte de données maximale acceptable |
| **RTO** (Recovery Time Objective) | **4 heures** — durée maximale d'interruption acceptable |

---

## 4. Moyens de protection déployés

### 4.1 Protection matérielle

| Moyen | Description | Compétence 3.17 |
|---|---|---|
| DELL T140 — alimentation redondante | Évite la coupure sur défaillance PSU | Disponibilité matérielle |
| VLAN isolés (10, 20, 30) | Isolation réseau — une panne ne se propage pas | Cloisonnement |
| vm-backup (VLAN 30 dédié) | VM dédiée aux sauvegardes, isolée de la production | Réplication des données |

### 4.2 Protection logicielle

| Moyen | Description | Compétence 3.17 |
|---|---|---|
| **Veeam Backup & Replication** | Sauvegarde quotidienne des VMs, chiffrement AES-256 | **Réplication des données** |
| **Volumes Docker nommés** | Persistance des données hors cycle de vie des containers | Disponibilité des données |
| **Traefik + Let's Encrypt** | Renouvellement automatique des certificats TLS | Disponibilité des applicatifs |
| **Watchtower** | Mise à jour automatique des images Docker | Intégrité des applicatifs |
| **Fail2ban** | Protection brute force SSH | Sécurité des accès |
| **FortiGate règles deny-all** | Blocage inter-VLAN non autorisé | Protection réseau |

### 4.3 Réplication des données (critère d'évaluation)

```
vm-streaming ──► Veeam B&R ──► vm-backup (/backup AES-256)
                    │
                    ├── Sauvegarde incrémentale quotidienne à 02h00
                    ├── Rétention : 7j quotidien / 4 semaines / 3 mois
                    └── Test de restauration mensuel (voir PROCEDURE_BACKUP_RESTORE.md)
```

**Preuve que les données répliquées sont disponibles et opérationnelles :**
- Rapport de test mensuel dans `docs/PROCEDURE_BACKUP_RESTORE.md` §4, tableau de suivi
- Vérification via `sudo veeamconfig session list --jobName "Backup_vm-streaming"` → `Status: Success`
- Test de restauration en environnement isolé : tous les containers démarrent, `pg_isready` = OK, `redis-cli ping` = PONG

---

## 5. Plan de Continuité d'Activité (PCA)

### 5.1 Scénarios et modes dégradés

| Scénario | Impact | Mode dégradé |
|---|---|---|
| Container tombé | Service indisponible | `docker restart <container>` — RTO < 5 min |
| vm-streaming redémarrée | Tous les services down | `make up` depuis `main` — RTO < 30 min |
| vm-dns indisponible | Résolution DNS interne KO | Fallback DNS public (8.8.8.8) sur FortiGate |
| Disque vm-streaming plein | Services instables | Purge logs Docker + nettoyage volumes orphelins |

### 5.2 Service minimal garanti

En cas de sinistre partiel, les services à maintenir en priorité sont :

```
1. PostgreSQL     → base de données (requis par Keycloak)
2. Redis          → cache sessions
3. Traefik        → accès HTTPS
4. Keycloak       → authentification
5. Jellyfin       → service principal
```

Commande de démarrage du service minimal :
```bash
docker compose -f docker/databases/docker-compose.yml up -d postgres redis
docker compose -f docker/proxy/docker-compose.yml up -d
docker compose -f docker/keycloak/docker-compose.yml up -d
docker compose -f docker/jellyfin/docker-compose.yml up -d
```

---

## 6. Plan de Reprise d'Activité (PRA)

### 6.1 Déclenchement

Le PRA est déclenché lorsque :
- La VM de production est irrémédiablement corrompue ou inaccessible
- Une panne matérielle DELL T140 nécessite une intervention physique
- Un ransomware chiffre les données de production

### 6.2 Procédure de reprise (résumé)

| Étape | Action | Responsable | Durée estimée |
|---|---|---|---|
| 1 | Évaluer l'impact et notifier l'équipe | Iman H. | 15 min |
| 2 | Isoler la VM défaillante (règle FortiGate) | Quentin | 10 min |
| 3 | Identifier le dernier point de restauration Veeam | Iman H. | 10 min |
| 4 | Restaurer la VM depuis Veeam vers Proxmox | Iman H. | 45–90 min |
| 5 | Vérifier les containers et données | Iman H. | 30 min |
| 6 | Réactiver les accès réseau | Quentin | 10 min |
| 7 | Valider les services applicatifs | Adrien | 15 min |
| 8 | Post-mortem et documentation | Tous | 24h après |

**RTO total estimé : 2h00–2h50** (dans la cible de 4 heures)

> Procédure détaillée : `docs/PROCEDURE_BACKUP_RESTORE.md` §5

### 6.3 Ordre de redémarrage des services

```
1. vm-dns          → DNS interne
2. PostgreSQL      → BDD principale
3. Redis           → cache
4. Vault           → secrets
5. Traefik         → proxy
6. Keycloak        → SSO
7. Jellyfin        → streaming
8. MinIO           → stockage médias
9. MongoDB         → historique
10. Grafana + Prometheus + Loki + Suricata → monitoring
```

---

## 7. Tests et validation

| Test | Fréquence | Responsable | Dernière exécution |
|---|---|---|---|
| Test de restauration Veeam en environnement isolé | Mensuel | Iman H. | 2026-06-22 ✅ |
| Vérification statut jobs Veeam | Hebdomadaire | Iman H. | — |
| Simulation panne container | Trimestriel | Tous | — |
| Simulation panne VM complète | Semestriel | Tous | — |

---

## 8. Contacts et responsabilités

| Rôle | Nom | Responsabilité PCA/PRA |
|---|---|---|
| Admin système & DevOps | Iman Hamdy | Pilote du PRA, restauration VMs, coordination |
| Admin réseau | Quentin | Isolation FortiGate, rétablissement accès réseau |
| Admin monitoring | Adrien | Détection incident (Suricata/Grafana), validation post-reprise |

---

## 9. Documents associés

| Document | Lien | Rôle dans le PCA/PRA |
|---|---|---|
| BIA | `docs/BIA.md` | RTO/RPO par service, ordre de priorité |
| Procédure backup/restore | `docs/PROCEDURE_BACKUP_RESTORE.md` | Procédure opérationnelle détaillée |
| Analyse de risques | `docs/ANALYSE_RISQUES.md` | Scénarios de sinistre (R02, R05) |
| Plan de déploiement | `docs/PLAN_DEPLOIEMENT.md` | Phases de reconstruction de l'infrastructure |
