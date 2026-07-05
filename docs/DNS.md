# DNS and `streaminglab.local`

This project uses the internal domain `streaminglab.local` for local service discovery.

## Recommended internal hostnames

Use the following hostnames in your internal DNS zone or Pi-hole/DNS server:

- `vm-streaming.streaminglab.local` — main streaming VM
- `vm-dns.streaminglab.local` — DNS/PI-hole VM
- `vm-backup.streaminglab.local` — backup VM
- `prometheus.streaminglab.local` — Prometheus
- `grafana.streaminglab.local` — Grafana
- `loki.streaminglab.local` — Loki
- `keycloak.streaminglab.local` — Keycloak
- `jellyfin.streaminglab.local` — Jellyfin
- `vault.streaminglab.local` — Vault
- `minio.streaminglab.local` — MinIO

## DNS zone setup

If you use Pi-hole or another internal DNS resolver, create the zone `streaminglab.local` and add static records for each service IP.

Example records:

- `streaminglab.local` -> `192.168.10.2`
- `grafana.streaminglab.local` -> `192.168.40.13`
- `prometheus.streaminglab.local` -> `192.168.40.10`
- `loki.streaminglab.local` -> `192.168.40.11`
- `jellyfin.streaminglab.local` -> `192.168.10.20`
- `keycloak.streaminglab.local` -> `192.168.10.30`

## Notes

- `.local` is used only for internal DNS; do not expose it publicly.
- If you need an external-facing domain later, keep `streaminglab.local` for internal resolution and use a separate public domain for external services.
