# Supplément ITIL / ISO 20000 — DAT Streaming Lab
**Ynov Campus B3 INFRA — Projet Streaming Lab**
Version 1.0 — Juin 2026

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

### Clause 6 — Planification
| Exigence ISO 20000 | Réalisation |
|---|---|
| 6.1 Actions face aux risques | Analyse des risques dans `PCA_PRA.docx` ; matrice VLAN/firewall |
| 6.2 Objectifs de services | RPO/RTO documentés ; disponibilité FortiGate HA |

### Clause 8 — Exploitation
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

### Clause 9 — Évaluation des performances
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

## 5. Références

- ITIL 4 Foundation — Axelos (2019)
- ISO/CEI 20000-1:2018 — Technologie de l'information — Gestion des services
- `docs/DAT_StreamingLab_v2.0.docx` — Architecture technique détaillée
- `docs/PCA_PRA.docx` — Plan de Continuité et de Reprise d'Activité
- `docs/CHARTE_INFORMATIQUE.md` — Politique de sécurité du SI
- `docs/PROCEDURE_BACKUP_RESTORE.md` — Procédure de sauvegarde et restauration
