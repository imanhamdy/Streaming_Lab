# DNS — Streaming Lab

## DNS public (Cloudflare)

Le domaine `duoowatch.com` est géré par Cloudflare. Les sous-domaines exposés pointent vers le tunnel Cloudflare via des enregistrements CNAME :

| Sous-domaine | Service |
|-------------|---------|
| `jellyfin.duoowatch.com` | Jellyfin 10.10.7 |
| `keycloak.duoowatch.com` | Keycloak 24 |
| `grafana.duoowatch.com` | Grafana |
| `minio.duoowatch.com` | MinIO Console |
| `vault.duoowatch.com` | HashiCorp Vault |
| `traefik.duoowatch.com` | Dashboard Traefik (basic auth) |

Aucun port entrant n'est ouvert sur le FortiGate — tout le trafic transite via le tunnel cloudflared sortant.

---

## DNS interne (DNS-01 — Raspberry Pi 3B+)

La résolution DNS interne est assurée par le **Raspberry Pi 3B+** (DNS-01) :

| Attribut | Valeur |
|----------|--------|
| Hostname | DNS-01 |
| IP | 192.168.20.20 |
| VLAN | 20 |
| Matériel | Raspberry Pi 3B+ |

> **Choix architectural :** une VM dédiée (vm-dns) avait été initialement envisagée. Le Raspberry Pi 3B+ existant sur le réseau remplit ce rôle sans consommer de ressources Proxmox supplémentaires.

### Enregistrements internes recommandés (`streaminglab.local`)

| Hostname | IP |
|----------|----|
| `vm-streaming.streaminglab.local` | 192.168.10.2 |
| `vm-backup.streaminglab.local` | 192.168.20.2 |
| `proxmox.streaminglab.local` | 192.168.90.50 |

### Résolution Docker

Les conteneurs se résolvent entre eux par leur **nom de service** Docker Compose sur le réseau Docker partagé. Aucune entrée DNS externe n'est nécessaire pour la communication inter-conteneurs.

---

## Flux de résolution

```
Utilisateur externe
    │ → jellyfin.duoowatch.com
    ▼
Cloudflare DNS (résolution publique + tunnel TLS)
    │
    ▼
cloudflared (tunnel sortant sur vm-streaming)
    │
    ▼
Traefik :80 → Jellyfin

Utilisateur interne (LAN)
    │ → vm-streaming.streaminglab.local
    ▼
DNS-01 Raspberry Pi (192.168.20.20)
    │
    ▼
192.168.10.2 (vm-streaming)
```
