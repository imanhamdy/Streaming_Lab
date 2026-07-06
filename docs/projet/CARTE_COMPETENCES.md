# Carte de Compétences — Grille d'évaluation UF INFRA

Ce document relie chaque critère de la grille d'évaluation « Compétences Générales » aux livrables concrets du dépôt, pour faciliter la relecture par le jury et vérifier qu'aucun critère n'est laissé sans preuve.

## 1. Architecture Réseau et Sécurité (pondération 5)

| Exigence | Preuve dans le dépôt |
|---|---|
| Architecture LAN/WAN complète | [docs/architecture/NETWORKS.md](../architecture/NETWORKS.md), [docs/architecture/DAT.md](../architecture/DAT.md) |
| Segmentation réseau | 3 réseaux Docker isolés `streaming-public` / `streaming-private` / `streaming-monitoring` (tous les `docker-compose.yml` sous [docker/](../../docker/)) |
| Filtrage, ACLs | [docker/databases/haproxy/haproxy.cfg](../../docker/databases/haproxy/haproxy.cfg), règles de reverse-proxy dans [docker/proxy/](../../docker/proxy/) |
| Zero Trust (SSO, MFA, coffre-fort de secrets) | [docker/keycloak/](../../docker/keycloak/), [docs/services/KEYCLOAK_SETUP.md](../services/KEYCLOAK_SETUP.md), [docker/security/vault-config.hcl](../../docker/security/vault-config.hcl), [docs/services/VAULT_SETUP.md](../services/VAULT_SETUP.md) |
| Détection de menaces | CrowdSec ([docker/security/docker-compose.yml](../../docker/security/docker-compose.yml), [docker/security/crowdsec-acquis.yaml](../../docker/security/crowdsec-acquis.yaml), [infra/crowdsec-demo/](../../infra/crowdsec-demo/)) |
| Test fonctionnel | [scripts/tests/test_network.sh](../../scripts/tests/test_network.sh), [scripts/tests/test_sso.sh](../../scripts/tests/test_sso.sh), [scripts/tests/test_vault.sh](../../scripts/tests/test_vault.sh) |

## 2. Infrastructure Cloud et Systèmes (pondération 4)

| Exigence | Preuve dans le dépôt |
|---|---|
| Architecture hybride On-premise / IaaS / PaaS | [docs/architecture/DAT.md](../architecture/DAT.md), [infra/ansible/](../../infra/ansible/) (provisioning VM) |
| Analyse comparative coûts/faisabilité | [docs/projet/COMPARATIF_SOLUTIONS.md](COMPARATIF_SOLUTIONS.md), [docs/projet/TCO.md](TCO.md), [docs/projet/GREEN_IT.md](GREEN_IT.md) |
| Déploiement et gestion de services | Stacks Docker Compose complets sous [docker/](../../docker/) (proxy, keycloak, databases, monitoring, security, storage, jellyfin) |
| Scripts de provisioning | [scripts/init-vm.sh](../../scripts/init-vm.sh), [infra/ansible/prepare-vm-streaming.yml](../../infra/ansible/prepare-vm-streaming.yml), [infra/ansible/prepare-vm-backup.yml](../../infra/ansible/prepare-vm-backup.yml) |

## 3. Gouvernance des Données — BDD & Stockage (pondération 4)

| Exigence | Preuve dans le dépôt |
|---|---|
| Stratégie de stockage et sauvegarde | [docs/sauvegarde/BACKUP_STRATEGY_321.md](../sauvegarde/BACKUP_STRATEGY_321.md), [docs/sauvegarde/PROCEDURE_BACKUP_RESTORE.md](../sauvegarde/PROCEDURE_BACKUP_RESTORE.md) |
| Administration BDD relationnelle (HA) | Cluster Patroni/PostgreSQL + HAProxy : [docker/databases/](../../docker/databases/) |
| Stockage objet (NoSQL / S3) | MinIO — [docs/architecture/DAT_section5_stockage_bdd.md](../architecture/DAT_section5_stockage_bdd.md), [docs/ITIL/RFC-001_MinIO_Storage.md](../ITIL/RFC-001_MinIO_Storage.md) |
| Sécurité des accès et intégrité | [docker/databases/init/01-users.sh](../../docker/databases/init/01-users.sh), [scripts/init-databases.sh](../../scripts/init-databases.sh) |
| Sauvegarde/restauration automatisée | [scripts/backup/backup_pgsql_to_minio.sh](../../scripts/backup/backup_pgsql_to_minio.sh), [scripts/backup/cleanup_old_dumps.sh](../../scripts/backup/cleanup_old_dumps.sh), [docs/sauvegarde/RESTORE_TEST_LOG.md](../sauvegarde/RESTORE_TEST_LOG.md) |
| Test fonctionnel (failover, restauration) | [scripts/tests/test_failover.sh](../../scripts/tests/test_failover.sh), [scripts/tests/test_replication.sh](../../scripts/tests/test_replication.sh), [scripts/tests/test_pgsql_restore.sh](../../scripts/tests/test_pgsql_restore.sh), [scripts/tests/test_minio_buckets.sh](../../scripts/tests/test_minio_buckets.sh) |

## 4. Gouvernance et Résilience — Sécurité, PCA/PRA (pondération 4)

| Exigence | Preuve dans le dépôt |
|---|---|
| Analyse des risques (BIA) | [docs/securite/BIA.md](../securite/BIA.md), [docs/securite/ANALYSE_RISQUES.md](../securite/ANALYSE_RISQUES.md) |
| PCA/PRA | [docs/securite/PCA_PRA.md](../securite/PCA_PRA.md) |
| Procédures d'incident majeur | [docs/securite/PLAN_URGENCE_MALWARE.md](../securite/PLAN_URGENCE_MALWARE.md), [docs/securite/PLAN_TELETRAVAIL.md](../securite/PLAN_TELETRAVAIL.md) |
| Gestion des incidents (ITSM) | [docs/ITIL/GESTION_INCIDENTS.md](../ITIL/GESTION_INCIDENTS.md), [docs/ITIL/GESTION_CHANGEMENTS.md](../ITIL/GESTION_CHANGEMENTS.md) |
| Supervision / observabilité | Stack Prometheus + Grafana + Loki + Alertmanager : [docker/monitoring/](../../docker/monitoring/), [monitoring/grafana/dashboards/](../../monitoring/grafana/dashboards/), règles d'alerte [docker/monitoring/prometheus/alerts.yml](../../docker/monitoring/prometheus/alerts.yml) |
| Test fonctionnel | [scripts/tests/test_monitoring.sh](../../scripts/tests/test_monitoring.sh), [scripts/tests/test_failover.sh](../../scripts/tests/test_failover.sh) |

## 5. DevOps et Automatisation (pondération 3)

| Exigence | Preuve dans le dépôt |
|---|---|
| Containerisation des services | Tous les services applicatifs sous [docker/](../../docker/) (proxy, keycloak, databases, monitoring, security, storage, jellyfin) |
| Pipelines CI/CD | [.github/workflows/ci.yml](../../.github/workflows/ci.yml), [.github/workflows/deploy.yml](../../.github/workflows/deploy.yml), [.github/workflows/security.yml](../../.github/workflows/security.yml), [.github/workflows/validate-compose.yml](../../.github/workflows/validate-compose.yml) |
| Infrastructure as Code | [infra/ansible/roles/](../../infra/ansible/roles/) (docker, node-exporter, backup-repository) |
| Scripts d'automatisation d'administration | [scripts/up.sh](../../scripts/up.sh), [scripts/restart.sh](../../scripts/restart.sh), [scripts/update-images.sh](../../scripts/update-images.sh), [scripts/vault-env.sh](../../scripts/vault-env.sh), [Makefile](../../Makefile) |

## 6. Qualité des livrables et de la démonstration (pondération 2)

| Exigence | Preuve dans le dépôt |
|---|---|
| DAT claire et complète | [docs/architecture/DAT.md](../architecture/DAT.md), [docs/architecture/DAT_StreamingLab_v2.0.docx](../architecture/DAT_StreamingLab_v2.0.docx) |
| Schémas d'architecture | [docs/architecture/UML_schemas/](../architecture/UML_schemas/) (architecture, gantt, roadmap) |
| Suivi de projet agile | [docs/projet/PLAN_DEPLOIEMENT.md](PLAN_DEPLOIEMENT.md), [docs/projet/TEAM_GUIDE.md](TEAM_GUIDE.md), [docs/projet/GITFLOW.md](GITFLOW.md) |
| Démonstration fonctionnelle (PoC) | Stack complète déployable via [scripts/up.sh](../../scripts/up.sh) + suite de tests [scripts/tests/test_all.sh](../../scripts/tests/test_all.sh) couvrant réseau, conteneurs, volumes, BDD, sauvegarde, monitoring, SSO et Vault |

---

*Ce document est une synthèse de traçabilité ; il ne remplace pas le DAT ni les procédures détaillées qu'il référence.*
