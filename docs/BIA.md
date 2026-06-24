# Business Impact Analysis (BIA) — Streaming Lab
**Ynov Campus B3 INFRA — BC03 Compétences 11 & 14**
Version 1.0 — Juin 2026

---

## 1. Objectif

Le BIA (Business Impact Analysis) identifie les services critiques du SI Streaming Lab, quantifie l'impact de leur interruption et définit les priorités de reprise. Il alimente directement le PCA/PRA (`docs/PCA_PRA.docx`).

---

## 2. Inventaire et criticité des services

| Service | Composant technique | Utilisateurs impactés | Criticité |
|---|---|---|---|
| Authentification SSO | Keycloak | Tous | 🔴 Critique |
| Streaming vidéo | Jellyfin | Tous | 🔴 Critique |
| Proxy / accès HTTPS | Traefik | Tous | 🔴 Critique |
| Base de données utilisateurs | PostgreSQL | Tous (indirect) | 🔴 Critique |
| Gestion des secrets | Vault | Admins + services | 🟠 Haute |
| DNS interne | vm-dns / Pi-hole | Tous (indirect) | 🟠 Haute |
| Stockage médias | MinIO | Tous | 🟠 Haute |
| Cache sessions | Redis | Tous (indirect) | 🟠 Haute |
| Historique / recommandations | MongoDB | Utilisateurs streaming | 🟡 Moyenne |
| Supervision | Grafana + Prometheus | Admins | 🟡 Moyenne |
| Logs | Loki + Promtail | Admins | 🟡 Moyenne |
| Détection d'intrusion | Suricata | Admins (sécurité) | 🟡 Moyenne |
| Sauvegarde | Veeam B&R | Admins | 🟡 Moyenne |

---

## 3. Analyse d'impact par service

### 3.1 Services Critiques 🔴

#### Keycloak (SSO / Authentification)
| Indicateur | Valeur |
|---|---|
| **Impact si indisponible** | Aucun utilisateur ne peut se connecter à aucun service |
| **Services dépendants** | Jellyfin, Grafana, Vault, tous les services protégés |
| **RTO cible** | **1 heure** |
| **RPO cible** | **0** (état Keycloak = BDD PostgreSQL, répliquée) |
| **Mode dégradé** | Impossible — pas d'authentification = pas de service |
| **Solution de continuité** | Restauration Keycloak depuis snapshot Veeam + PostgreSQL |

#### Traefik (Proxy HTTPS)
| Indicateur | Valeur |
|---|---|
| **Impact si indisponible** | Aucun service accessible depuis l'extérieur |
| **RTO cible** | **30 minutes** |
| **RPO cible** | N/A (stateless, certificats dans volume persistant) |
| **Mode dégradé** | Accès direct aux services via IP interne (VPN requis) |
| **Solution de continuité** | `docker compose up traefik` — redémarrage < 1 min |

#### Jellyfin (Streaming)
| Indicateur | Valeur |
|---|---|
| **Impact si indisponible** | Service principal indisponible — impact direct utilisateurs |
| **RTO cible** | **2 heures** |
| **RPO cible** | **24 heures** (contenu média sur MinIO) |
| **Mode dégradé** | N/A |
| **Solution de continuité** | Restauration VM + redémarrage stack |

#### PostgreSQL (Base utilisateurs)
| Indicateur | Valeur |
|---|---|
| **Impact si indisponible** | Keycloak non fonctionnel → tous les services bloqués |
| **RTO cible** | **1 heure** |
| **RPO cible** | **24 heures** (sauvegarde Veeam quotidienne) |
| **Mode dégradé** | Impossible |
| **Solution de continuité** | Restauration volume depuis Veeam |

---

### 3.2 Services Haute priorité 🟠

| Service | RTO | RPO | Mode dégradé |
|---|---|---|---|
| Vault | 2h | 24h | Services utilisent derniers secrets en cache |
| vm-dns / Pi-hole | 1h | N/A (config statique) | DNS public (8.8.8.8) en fallback |
| MinIO | 4h | 24h | Fichiers médias indisponibles (streaming dégradé) |
| Redis | 30min | 0 (cache) | Keycloak ralenti, sessions perdues |

---

### 3.3 Services Moyenne priorité 🟡

| Service | RTO | RPO | Impact interruption |
|---|---|---|---|
| MongoDB | 8h | 24h | Perte historique/reco uniquement |
| Grafana | 4h | 24h | Monitoring aveugle temporairement |
| Prometheus | 4h | 1h | Métriques perdues pendant interruption |
| Loki | 8h | 1h | Logs non collectés pendant interruption |
| Suricata | 4h | N/A | Pas de détection IDS pendant interruption |
| Veeam B&R | 24h | N/A | Sauvegardes suspendues |

---

## 4. Cartographie des dépendances critiques

```
Internet
   │
   ▼
Traefik (🔴)
   │
   ├──► Keycloak (🔴) ──► PostgreSQL (🔴)
   │         │
   │         └──► Redis (🟠) [sessions]
   │
   ├──► Jellyfin (🔴) ──► MinIO (🟠) [médias]
   │                └──► MongoDB (🟡) [historique]
   │
   ├──► Vault (🟠)
   │
   └──► Grafana (🟡)
              │
              ├──► Prometheus (🟡)
              └──► Loki (🟡) ◄── Suricata (🟡)

vm-dns (🟠) ◄── tous les services [résolution DNS]
vm-backup (🟡) ◄── toutes les VMs [sauvegardes Veeam]
```

**Chemin critique :** `vm-streaming → Traefik → Keycloak → PostgreSQL`
Si l'un de ces 4 éléments tombe, **tous les utilisateurs sont impactés**.

---

## 5. Tableau synthétique RTO / RPO

| Service | Criticité | RTO | RPO | Solution continuité |
|---|---|---|---|---|
| Traefik | 🔴 Critique | 30 min | N/A | docker restart |
| Keycloak | 🔴 Critique | 1h | 0 | Restauration Veeam + PG |
| PostgreSQL | 🔴 Critique | 1h | 24h | Restauration Veeam |
| Jellyfin | 🔴 Critique | 2h | 24h | Restauration Veeam |
| vm-dns | 🟠 Haute | 1h | N/A | Redémarrage VM |
| Redis | 🟠 Haute | 30 min | 0 | docker restart |
| MinIO | 🟠 Haute | 4h | 24h | Restauration Veeam |
| Vault | 🟠 Haute | 2h | 24h | Restauration Veeam |
| MongoDB | 🟡 Moyenne | 8h | 24h | Restauration Veeam |
| Grafana | 🟡 Moyenne | 4h | 24h | docker restart |
| Suricata | 🟡 Moyenne | 4h | N/A | docker restart |

---

## 6. Ressources minimales pour continuité opérationnelle

En mode dégradé minimum (service streaming disponible uniquement) :

| Ressource | Minimum requis |
|---|---|
| Serveur physique | DELL T140 opérationnel |
| VM | vm-streaming uniquement |
| Containers actifs | Traefik, Keycloak, PostgreSQL, Redis, Jellyfin |
| RAM minimum | 4 Go |
| CPU minimum | 2 vCPU |
| Stockage minimum | 50 Go (OS + BDD) + volume médias MinIO |
| Réseau | VLAN 20 opérationnel + accès internet pour Let's Encrypt |

---

## 7. Priorisation de reprise (ordre de redémarrage)

En cas de redémarrage complet après sinistre :

```
1. vm-dns          → résolution DNS interne
2. PostgreSQL      → base de données (requis par Keycloak)
3. Redis           → cache sessions
4. Vault           → secrets (requis par services)
5. Traefik         → proxy HTTPS
6. Keycloak        → authentification
7. Jellyfin        → service streaming
8. MinIO           → stockage médias
9. MongoDB         → historique/reco
10. Grafana + Prometheus + Loki + Suricata → monitoring
```

Cet ordre est implémenté dans le `Makefile` via `make up`.
