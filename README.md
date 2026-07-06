# Streaming Lab

Infrastructure homelab de streaming video sur Proxmox VE 8 - Ynov Campus B3 INFRA.

## Acces aux services

| Service | URL | Description |
|---|---|---|
| Jellyfin | https://jellyfin.duoowatch.com | Streaming video |
| Keycloak | https://keycloak.duoowatch.com | SSO / Authentification |
| Grafana | https://grafana.duoowatch.com | Supervision & metriques |
| MinIO | https://minio.duoowatch.com | Stockage objet S3 |
| Vault | https://vault.duoowatch.com | Gestion des secrets |
| Traefik | https://traefik.duoowatch.com | Dashboard proxy (VPN requis) |

## Stack technique

- **Proxmox VE 8** - hyperviseur sur DELL T140
- **Docker Compose** - stacks isolees par domaine fonctionnel
- **Traefik v3** - reverse proxy HTTPS + Let's Encrypt
- **Keycloak 24** - SSO OIDC + MFA
- **HashiCorp Vault 1.17** - secrets & PKI
- **PLG Stack** - Prometheus + Loki + Grafana
- **Suricata** - IDS reseau
- **MinIO** - stockage objet compatible S3
- **Veeam B&R** - sauvegardes AES-256

## CI/CD

| Check | Declencheur |
|---|---|
| YAML lint + Compose validate | PR -> develop / main |
| Trivy (scan CVE CRITICAL) | PR -> develop / main |
| Gitleaks (detection secrets) | PR -> develop / main |
| Deploy auto sur vm-streaming | Merge -> develop |

## Documentation

| Document | Contenu |
|---|---|
| [CARTE_COMPETENCES](docs/projet/CARTE_COMPETENCES.md) | Mapping grille d'evaluation UF INFRA <-> livrables |
| [CHARTE_INFORMATIQUE](docs/securite/CHARTE_INFORMATIQUE.md) | Politique de securite |
| [ANALYSE_RISQUES](docs/securite/ANALYSE_RISQUES.md) | Matrice de risques ISO 27005 |
| [BIA](docs/securite/BIA.md) | Business Impact Analysis - RTO/RPO |
| [PLAN_URGENCE_MALWARE](docs/securite/PLAN_URGENCE_MALWARE.md) | Reponse aux incidents malware |
| [PLAN_TELETRAVAIL](docs/securite/PLAN_TELETRAVAIL.md) | Plan teletravail securise |
| [PROCEDURE_BACKUP_RESTORE](docs/sauvegarde/PROCEDURE_BACKUP_RESTORE.md) | Sauvegarde & restauration |
| [DAT_ITIL_SUPPLEMENT](docs/ITIL/DAT_ITIL_SUPPLEMENT.md) | ITIL v4 + ISO 20000 + ISO 27001 |
| [COMPARATIF_SOLUTIONS](docs/projet/COMPARATIF_SOLUTIONS.md) | TCO & justification des choix |
| [PLAN_DEPLOIEMENT](docs/projet/PLAN_DEPLOIEMENT.md) | Plan de deploiement par phases |
| [GREEN_IT](docs/projet/GREEN_IT.md) | Indicateurs Green IT & RSE |

## Equipe

| Membre | Role |
|---|---|
| Iman Hamdy | Admin systeme & DevOps |
| Quentin | Admin reseau |
| Adrien | Admin monitoring |