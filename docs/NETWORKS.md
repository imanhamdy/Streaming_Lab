# Network Plan and IP Ranges

This document lists the Docker networks used by the project and the IP address ranges assigned.

## Networks

- `streaming-net` — subnet: `192.168.10.0/24`
  - gateway: `192.168.10.1` (Docker-managed)
  - example VM: `vm-streaming` -> `192.168.10.2`

- `db-net` — subnet: `192.168.20.0/24`
  - gateway: `192.168.20.1`
  - example VM: `vm-dns` -> `192.168.20.2`

- `storage-net` — subnet: `192.168.30.0/24`
  - gateway: `192.168.30.1`
  - example VM: `vm-backup` -> `192.168.30.2`

- `monitoring-net` — subnet: `192.168.40.0/24`
  - gateway: `192.168.40.1`
  - services: Prometheus, Grafana, Loki

## Example static container IP assignments (recommended)

- `monitoring-net`:
  - `prometheus` -> `192.168.40.10`
  - `loki` -> `192.168.40.11`
  - `promtail` -> `192.168.40.12`
  - `grafana` -> `192.168.40.13`

When using static container IPs with Docker Compose, declare the network as external and assign `ipv4_address` per service. Example in `docker/monitoring/docker-compose.yml`.

## DNS and internal domain

- The internal DNS domain for this lab is `streaminglab.local`.
- Map service hostnames inside the lab to container or VM IPs using your internal DNS server.
- Example hostnames:
  - `prometheus.streaminglab.local`
  - `grafana.streaminglab.local`
  - `jellyfin.streaminglab.local`
  - `keycloak.streaminglab.local`
  - `vault.streaminglab.local`

## Notes

- These subnets are configured by `scripts/init-vm.sh` when creating the Docker networks.
- If you change subnets, be sure to update `docs/NETWORKS.md` and any static IPs in VM or container configs.
- Use the following commands to list networks and inspect subnets:

```bash
docker network ls
docker network inspect streaming-net
```

## Recommended static IP assignments

- Reserve the `.1` address for the Docker gateway on each network.
- Use `.2` for the main VM/container providing that network (example above).
- Document any additional static assignments in this file as required.
