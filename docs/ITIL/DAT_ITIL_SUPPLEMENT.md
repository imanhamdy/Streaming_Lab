# Supplément ITIL / ISO 20000 - DAT Streaming Lab
**Ynov Campus B3 INFRA - Projet Streaming Lab**
Version 1.0 - Juin 2026

> Ce document complète le DAT (`DAT_StreamingLab_v2.0.docx`) en positionnant
> l'infrastructure Streaming Lab dans le cadre des bonnes pratiques
> **ITIL v4** et de la norme **ISO/CEI 20000-1**.

---

## 1. Positionnement ITIL v4

### 1.1 Chaîne de valeur des services (Service Value Chain)

ITIL v4 définit une chaîne de valeur à 6 activités. Le tableau ci-dessous
positionne les composants du Streaming Lab dans cette chaîne :

| Activité ITIL | Composants Streaming Lab |
|---|---|
| **Planifier** | Jira (KAN board), Git flow, branches feature/* |
| **Améliorer** | CI/CD GitHub Actions, tests automatisés (`.github/workflows/`) |
| **Engager** | Documentation (`docs/`), `TEAM_GUIDE.md`, réunions d'équipe |
| **Concevoir & Transitionner** | Feature branches → develop → main, PR reviews |
| **Obtenir & Construire** | Docker Compose stacks, Ansible (IaC), Terraform |
| **Fournir & Soutenir** | Grafana + Prometheus + Loki (supervision), Suricata (IDS) |

### 1.2 Pratiques ITIL couvertes

| Pratique ITIL | Mise en œuvre dans le projet |
|---|---|
| **Gestion des incidents** | Suricata → Loki → alertes Grafana ; procédure `PROCEDURE_BACKUP_RESTORE.md` |
| **Gestion des problèmes** | Analyse root cause via logs Loki ; post-mortem documentés |
| **Gestion des changements** | Pull Requests obligatoires, 1 reviewer minimum, merge dans develop uniquement |
| **Gestion des configurations (CMDB)** | Infrastructure as Code : Compose files, `scripts/init-vm.sh`, `.env.example` |
| **Gestion des niveaux de service (SLM)** | RPO 24h / RTO 4h définis dans `PROCEDURE_BACKUP_RESTORE.md` |
| **Gestion de la disponibilité** | FortiGate HA, `restart: unless-stopped`, Veeam B&R |
| **Gestion de la capacité** | Prometheus métriques CPU/RAM, alertes Grafana |
| **Gestion de la sécurité de l'information** | `CHARTE_INFORMATIQUE.md`, Vault, Keycloak, VLAN segmentation |
| **Gestion des déploiements** | CI/CD GitHub Actions, Makefile (`make up-<stack>`) |
| **Gestion des connaissances** | Dépôt `docs/` versionné dans Git (DAT, PCA/PRA, GITFLOW, DNS, NETWORKS) |

---

## 2. Alignement ISO/CEI 20000-1

La norme ISO/CEI 20000-1 définit les exigences d'un Système de Management
des Services (SMS). Le Streaming Lab couvre les clauses suivantes :

### Clause 6 - Planification
| Exigence ISO 20000 | Réalisation |
|---|---|
| 6.1 Actions face aux risques | Analyse des risques dans `PCA_PRA.docx` ; matrice VLAN/firewall |
| 6.2 Objectifs de services | RPO/RTO documentés ; disponibilité FortiGate HA |

### Clause 8 - Exploitation
| Exigence ISO 20000 | Réalisation |
|---|---|
| 8.2 Catalogue des services | Services Docker : Jellyfin, Keycloak, Vault, MinIO, bases de données |
| 8.3 Gestion des actifs | Inventaire dans le DAT : DELL T140, Cisco C3650, FortiGate, 3 VMs |
| 8.5 Gestion des incidents | Suricata + Grafana + procédure de réponse aux incidents |
| 8.6 Gestion des problèmes | Analyse logs Loki, post-mortem documentés |
| 8.7 Gestion des changements | Git flow + PR reviews + CI/CD |
| 8.8 Gestion des mises en production | Pipeline GitHub Actions : build → test → deploy |
| 8.9 Gestion de la continuité | PCA/PRA + Veeam B&R + tests de restauration mensuels |
| 8.10 Gestion de la sécurité | `CHARTE_INFORMATIQUE.md` + Keycloak + Vault + FortiGate + Suricata |
| 8.11 Gestion des configurations | IaC versionné dans Git (Compose, scripts, Ansible) |

### Clause 9 - Évaluation des performances
| Exigence ISO 20000 | Réalisation |
|---|---|
| 9.1 Surveillance et mesure | Prometheus (métriques) + Loki (logs) + Grafana (tableaux de bord) |
| 9.2 Audit interne | Code reviews via GitHub PRs, CI/CD quality gates |

---

## 3. Glossaire ITIL / ISO 20000

| Terme | Définition | Application dans le projet |
|---|---|---|
| **SLA** (Service Level Agreement) | Accord de niveau de service entre fournisseur et client | RPO 24h / RTO 4h pour vm-streaming |
| **RPO** (Recovery Point Objective) | Perte de données maximale acceptable | 24 heures (sauvegarde quotidienne Veeam) |
| **RTO** (Recovery Time Objective) | Durée maximale de restauration | 4 heures |
| **CMDB** (Configuration Management DB) | Base de données des éléments de configuration | Infrastructure as Code dans Git |
| **CI** (Configuration Item) | Élément de configuration géré | VMs, containers, configs réseau |
| **Incident** | Interruption non planifiée d'un service | Alerte Suricata / container down |
| **Problème** | Cause sous-jacente d'incidents récurrents | Analyse root cause via Loki |
| **Changement** | Modification d'un CI en production | Pull Request approuvée → merge develop |
| **Mise en production** (Release) | Déploiement d'un changement validé | `make up-<stack>` après merge main |
| **Tableau de bord** | Vue consolidée des indicateurs de service | Grafana dashboards (métriques + logs + alertes) |

---

## 4. Tableau de bord de suivi des services (KPIs)

Les indicateurs ci-dessous sont mesurés et visualisés dans Grafana :

| KPI | Source | Seuil d'alerte | Objectif |
|---|---|---|---|
| Disponibilité globale des services | Prometheus (up/down) | < 99% | ≥ 99.5% |
| Temps de réponse Traefik | Prometheus | > 500ms | < 200ms |
| Utilisation CPU vm-streaming | Prometheus node-exporter | > 80% | < 70% |
| Utilisation RAM vm-streaming | Prometheus node-exporter | > 85% | < 75% |
| Espace disque MinIO | Prometheus | > 80% | < 70% |
| Connexions actives PostgreSQL | Prometheus postgres-exporter | > 80 | < 50 |
| Alertes Suricata (24h) | Loki | > 10 | 0 |
| Jobs de sauvegarde Veeam | Loki / monitoring | Échec | 100% succès |

---

## 5. Conformité ISO 27001 - Annexe A (contrôles appliqués)

La norme ISO 27001:2022 définit 93 contrôles répartis en 4 thèmes. Le tableau ci-dessous liste les contrôles couverts par le Streaming Lab.

### Thème A.5 - Contrôles organisationnels

| Contrôle | Intitulé | Mise en œuvre | Statut |
|---|---|---|---|
| A.5.1 | Politiques de sécurité | `docs/CHARTE_INFORMATIQUE.md` | ✅ |
| A.5.2 | Rôles et responsabilités | `CHARTE_INFORMATIQUE.md` section 8 | ✅ |
| A.5.7 | Renseignement sur les menaces | `ANALYSE_RISQUES.md` | ✅ |
| A.5.10 | Utilisation acceptable des actifs | `CHARTE_INFORMATIQUE.md` section 7 | ✅ |
| A.5.29 | Sécurité des informations en cas de perturbation | `PCA_PRA.docx`, `BIA.md` | ✅ |
| A.5.30 | Préparation des TIC pour la continuité | `PROCEDURE_BACKUP_RESTORE.md` | ✅ |

### Thème A.6 - Contrôles liés aux personnes

| Contrôle | Intitulé | Mise en œuvre | Statut |
|---|---|---|---|
| A.6.3 | Sensibilisation, formation sécurité | `CHARTE_INFORMATIQUE.md` diffusée à l'équipe | ✅ |
| A.6.7 | Télétravail | `PLAN_TELETRAVAIL.md` | ✅ |
| A.6.8 | Signalement des événements | `GESTION_INCIDENTS.md` section 4 | ✅ |

### Thème A.7 - Contrôles physiques

| Contrôle | Intitulé | Mise en œuvre | Statut |
|---|---|---|---|
| A.7.1 | Périmètres de sécurité physique | Salle serveur Ynov Campus (accès restreint) | ✅ |
| A.7.6 | Travail dans les zones sécurisées | Accès physique serveur = personnel autorisé uniquement | ✅ |
| A.7.14 | Mise au rebut sécurisée | Politique documentée dans `CHARTE_INFORMATIQUE.md` | 📋 |

### Thème A.8 - Contrôles technologiques

| Contrôle | Intitulé | Mise en œuvre | Statut |
|---|---|---|---|
| A.8.2 | Droits d'accès privilégiés | Keycloak RBAC + principe moindre privilège | ✅ |
| A.8.3 | Restriction d'accès aux informations | Réseaux Docker isolés (db-net, storage-net) | ✅ |
| A.8.4 | Accès au code source | GitHub - branches protégées, PR obligatoires | ✅ |
| A.8.5 | Authentification sécurisée | MFA FortiClient + Keycloak SSO + MFA | ✅ |
| A.8.6 | Gestion de la capacité | Prometheus métriques CPU/RAM + alertes Grafana | ✅ |
| A.8.7 | Protection contre les malwares | Suricata IDS + images Docker officielles + Watchtower | ✅ |
| A.8.8 | Gestion des vulnérabilités techniques | Watchtower (MAJ auto images) + scan CI/CD | 🔄 |
| A.8.9 | Gestion de la configuration | Infrastructure as Code (Git + Compose + Ansible) | ✅ |
| A.8.12 | Prévention des fuites de données | `.gitignore` + Vault + `.env` non commité | ✅ |
| A.8.13 | Sauvegarde des informations | Veeam B&R AES-256 quotidien + tests restauration | ✅ |
| A.8.15 | Journalisation | Loki + Promtail - logs centralisés 7 jours | ✅ |
| A.8.16 | Surveillance des activités | Grafana dashboards + Suricata alertes | ✅ |
| A.8.20 | Sécurité des réseaux | VLAN segmentation + FortiGate deny-all inter-VLAN | ✅ |
| A.8.21 | Sécurité des services réseau | Traefik TLS 1.3 + Let's Encrypt + FortiGate VPN | ✅ |
| A.8.22 | Cloisonnement des réseaux | 4 réseaux Docker isolés + 7 VLANs | ✅ |
| A.8.24 | Utilisation de la cryptographie | TLS 1.3 (Traefik) + AES-256 (Veeam) + Vault PKI | ✅ |
| A.8.28 | Codage sécurisé | Secrets dans Vault/`.env`, pas dans le code | ✅ |

**Légende :** ✅ Contrôle appliqué | 🔄 En cours | 📋 Planifié

---

## 6. Routage Traefik - exposition des services

Traefik v3 agit comme reverse proxy HTTPS unique pour tous les services exposés. Chaque service est déclaré via des labels Docker et obtient un certificat TLS automatiquement via Let's Encrypt (challenge TLS-ALPN).

| Sous-domaine | Service | Port interne | Stack |
|---|---|---|---|
| traefik.duoowatch.com | Dashboard Traefik | 8080 | proxy |
| keycloak.duoowatch.com | Keycloak SSO / OIDC | 8080 | keycloak |
| vault.duoowatch.com | HashiCorp Vault (secrets, PKI) | 8200 | security |
| jellyfin.duoowatch.com | Jellyfin (streaming vidéo) | 8096 | jellyfin |
| grafana.duoowatch.com | Grafana (supervision) | 3000 | monitoring |
| minio.duoowatch.com | MinIO console (stockage S3) | 9001 | storage |

**Règles de sécurité Traefik :**
- Redirection HTTP → HTTPS automatique (entrypoint `web` → `websecure`)
- `exposedByDefault=false` - seuls les services avec `traefik.enable=true` sont exposés
- TLS 1.2 minimum imposé
- Dashboard protégé (`traefik.duoowatch.com`) - accès restreint VPN

---

## 7. Références

- ITIL 4 Foundation - Axelos (2019)
- ISO/CEI 20000-1:2018 - Technologie de l'information - Gestion des services
- `docs/DAT_StreamingLab_v2.0.docx` - Architecture technique détaillée
- `docs/PCA_PRA.docx` - Plan de Continuité et de Reprise d'Activité
- `docs/CHARTE_INFORMATIQUE.md` - Politique de sécurité du SI
- `docs/PROCEDURE_BACKUP_RESTORE.md` - Procédure de sauvegarde et restauration
