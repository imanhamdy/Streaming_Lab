# Ansible — Streaming Lab IaC

Automates VM preparation for vm-streaming and vm-backup.

## Usage

```bash
# Check connectivity
ansible all -i inventory.ini -m ping

# Prepare vm-streaming (Docker, networks, cron, node-exporter)
ansible-playbook -i inventory.ini prepare-vm-streaming.yml

# Prepare vm-backup (backup dirs, node-exporter, Veeam prereqs)
ansible-playbook -i inventory.ini prepare-vm-backup.yml

# Dry-run
ansible-playbook -i inventory.ini prepare-vm-streaming.yml --check
```

## Roles

| Role | What it does |
|------|-------------|
| `docker` | Installs Docker Engine + Compose plugin, adds user to docker group |
| `node-exporter` | Installs and starts Prometheus node_exporter as systemd service |
| `backup-repository` | Creates /backup directory structure, installs Veeam prerequisites |

## Playbooks

| Playbook | Target | Purpose |
|----------|--------|---------|
| `prepare-vm-streaming.yml` | vm-streaming | Docker, Docker networks, cron backup jobs, Jellyfin media dir |
| `prepare-vm-backup.yml` | vm-backup | /backup dirs, Veeam prereqs, node-exporter |
