# Streaming Lab — Ynov Campus B3 INFRA Projet Fil Rouge

Infrastructure de streaming auto-hébergée déployée sur un serveur Dell T140 / Proxmox VE 8.

## Architecture

| VM | IP | Rôle |
|----|----|------|
| vm-streaming | 192.168.10.2 | Stack Docker (Traefik, Jellyfin, Keycloak, …) |
| vm-dns | 192.168.20.2 | DNS interne |
| vm-backup | 192.168.30.2 | Sauvegardes |

Domaine interne : `streaminglab.local`

DNS interne : configurez la zone `streaminglab.local` dans votre serveur DNS ou Pi-hole.

## Déploiement rapide

```bash
cp .env.example .env
# Remplir .env avec vos valeurs

make up-proxy
make up-databases
make up-keycloak
make up-jellyfin
```

## Commandes utiles

| Commande | Action |
|----------|--------|
| `make up` | Démarre toutes les stacks |
| `make down` | Arrête toutes les stacks |
| `make up-<stack>` | Démarre une stack (ex: `make up-proxy`) |
| `make logs-<stack>` | Affiche les logs d'une stack |
| `make ps` | Liste les conteneurs actifs |

## Structure

```
streaming-lab/
├── docker/          Stacks Docker (une par service)
├── docs/            DAT, PCA/PRA, schémas UML
├── infra/           Terraform (Proxmox) + Ansible
├── monitoring/      Dashboards Grafana, configs Prometheus/Loki
├── network/         Configs FortiGate, VLANs, DNS
└── scripts/         Scripts utilitaires
```
