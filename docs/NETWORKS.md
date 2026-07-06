# Plan réseau — Streaming Lab

Ce document décrit l'architecture réseau complète : équipements physiques, VLANs, et réseaux Docker sur vm-streaming.

---

## Infrastructure physique

| Équipement | Modèle | IP | VLAN |
|-----------|--------|----|------|
| Firewall | FortiGate 60F | 10.0.0.1 | — |
| Switch | Cisco 3650 48P (SW-01) | 192.168.90.10 | VLAN 90 |
| Hyperviseur | Dell T140 — Proxmox VE 8 (PROX-01) | 192.168.90.50 | VLAN 90 |
| DNS physique | Raspberry Pi 3B+ (DNS-01) | 192.168.20.20 | VLAN 20 |

> **vm-dns supprimé :** la résolution DNS était initialement prévue sur une VM dédiée (vm-dns). Ce rôle est assuré par le Raspberry Pi 3B+ (DNS-01), équipement physique existant sur VLAN 20 — une VM dédiée aurait été redondante et moins économique en ressources.

---

## VLANs (FortiGate 60F + Cisco 3650 48P)

| VLAN | Réseau | Usage | Équipements |
|------|--------|-------|-------------|
| 10 | 192.168.10.0/24 | Services applicatifs | vm-streaming (192.168.10.2) |
| 20 | 192.168.20.0/24 | DNS physique | DNS-01 Pi (192.168.20.20) |
| 30 | 192.168.30.0/24 | Sauvegardes | vm-backup (192.168.30.2) · Veeam Repository |
| 90 | 192.168.90.0/24 | Management | Proxmox (192.168.90.50) · SW-01 (192.168.90.10) |

Le FortiGate applique des ACLs entre VLANs : le VLAN 10 (services) ne peut pas initier de connexion vers le VLAN 20 (sauvegardes) sauf sur les ports autorisés.

---

## Réseaux Docker (vm-streaming)

Trois réseaux Docker structurent l'isolation des services :

### streaming-public

```
Mode     : bridge
Scope    : vm-streaming
Accès    : Internet via Cloudflare Tunnel → Traefik
Services : Traefik, Jellyfin, Keycloak, MinIO, Vault, Grafana, TrivyHub, CrowdSec
```

Point d'entrée de tout le trafic externe. Traefik route vers le bon conteneur selon le hostname. CrowdSec analyse les logs Traefik sur ce réseau.

### streaming-private

```
Mode     : bridge --internal  ← ISOLÉ, aucune route Internet
Scope    : vm-streaming
Accès    : uniquement depuis streaming-public via haproxy-postgres
Services : etcd, haproxy-postgres, postgres-01, postgres-02
```

Réseau **--internal** : les conteneurs sur ce réseau n'ont aucun accès Internet. Seul haproxy-postgres est joignable depuis streaming-public (pour que Keycloak se connecte à la DB). Les nœuds PostgreSQL et etcd sont strictement isolés.

### streaming-monitoring

```
Mode     : bridge
Scope    : vm-streaming
Accès    : interne uniquement (Grafana exposé via streaming-public aussi)
Services : Prometheus, Loki, Grafana, Alertmanager, Promtail, cAdvisor,
           node-exporter, postgres-exporter
```

Stack d'observabilité. Prometheus scrape les exporters toutes les 15s. Promtail collecte les logs Docker et les syslog FortiGate.

---

## Stockage objet — MinIO (non-relationnel)

MinIO fournit un stockage S3 compatible clé-valeur (modèle non-relationnel) en remplacement de MongoDB ou Redis :

| Bucket | Usage |
|--------|-------|
| `backups` | Sauvegardes Veeam et fichiers système |
| `db-dumps` | Exports PostgreSQL quotidiens (cron) |
| `streaming-media` | Bibliothèque média Jellyfin |

> Ce choix est délibéré : aucun service du stack (Keycloak, Jellyfin, Grafana) ne requiert MongoDB ou Redis. MinIO couvre le besoin de stockage objet non-structuré avec une empreinte opérationnelle réduite.

---

## DNS interne

- **Domaine public :** `duoowatch.com` géré par Cloudflare (CNAMEs vers tunnel)
- **Domaine interne :** `streaminglab.local` résolu par DNS-01 (Raspberry Pi 3B+, 192.168.20.20)
- **Résolution Docker :** les conteneurs se résolvent par nom de service sur leur réseau Docker

Enregistrements internes recommandés (DNS-01) :

| Hostname | IP |
|----------|----|
| `vm-streaming.streaminglab.local` | 192.168.10.2 |
| `vm-backup.streaminglab.local` | 192.168.30.2 |

---

## Commandes de vérification

```bash
# Lister les réseaux Docker
docker network ls

# Inspecter un réseau
docker network inspect streaming-private

# Vérifier l'isolation du réseau privé (doit échouer)
docker exec postgres-01 curl -s --max-time 3 https://google.com

# État du cluster Patroni
docker exec postgres-01 patronictl -c /etc/patroni/patroni.yml list
```
