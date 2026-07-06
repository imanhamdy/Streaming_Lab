# Plan de Déploiement - Streaming Lab
**Ynov Campus B3 INFRA - Compétence 4 (BC02)**
Version 1.0 - Juin 2026

> Diagramme de Gantt disponible : `docs/UML_schemas/gantt_deploiement.svg`

---

## 1. Contraintes de planification

| Contrainte | Description |
|---|---|
| **Disponibilités équipe** | 3 membres, chacun responsable de domaines distincts (voir TEAM_GUIDE.md) |
| **Dépendances techniques** | Réseau doit être opérationnel avant déploiement des stacks Docker |
| **Fenêtres de maintenance** | Interventions réseau hors heures ouvrées (après 18h ou week-ends) |
| **Environnement partagé** | Un seul serveur physique DELL T140 - pas de rollback matériel possible |
| **Contrainte budget** | Aucun achat supplémentaire autorisé hors matériel déjà inventorié |

---

## 2. Dépendances critiques

```
[KAN-29 Proxmox]
       │
       ├──► [KAN-30/31/32 VMs] ──► [KAN-33 Docker networks]
       │                                      │
       │                         ┌────────────┼─────────────┐
       │                         ▼            ▼             ▼
       │                    [KAN-18 BDD]  [KAN-19 Monit] [Docker stacks]
       │
[KAN-7 Switch HP]
       │
       ├──► [KAN-23 VLANs] ──► [KAN-24 Policies FortiGate]
       │                                   │
[KAN-22 FortiGate HA] ◄──────────────────┘
       │
       ├──► [KAN-27 VPN SSL + MFA] ──► [KAN-25 Cloudflare ZT]
       │
       └──► [KAN-26 Guacamole]
```

---

## 3. Phasage du déploiement

### Phase 1 - Infrastructure fondatrice (S16–S18 · Avril 2026)
**Responsable : Quentin**
| Tâche | KAN | Statut |
|---|---|---|
| Installer et configurer Proxmox VE 8 | KAN-29 | ✅ Terminé |
| Créer vm-streaming, vm-dns, vm-backup | KAN-30/31/32 | ✅ Terminé |
| Créer les 4 réseaux Docker | KAN-33 | ✅ Terminé |

> Critère de passage à Phase 2 : les 3 VMs répondent au ping depuis le réseau interne.

---

### Phase 2 - Réseau et sécurité périmétrique (S16–S25 · Avril–Juin 2026)
**Responsable : Quentin + Iman Hamdy**
| Tâche | KAN | Statut |
|---|---|---|
| Configurer FortiGate HA (VIP 192.168.1.20) | KAN-22 | 🔄 En cours |
| Configurer le switch HP (trunk, access ports) | KAN-7 | 🔄 En cours |
| VPN SSL FortiClient + MFA | KAN-27 | ✅ Terminé |
| Créer et tagger les VLANs sur HP | KAN-23 | 📋 Planifié (S25–S26) |
| Policies FortiGate par VLAN | KAN-24 | 🔄 En cours |
| Cloudflare Zero Trust Tunnel | KAN-25 | 📋 Planifié (S26–S27) |
| Apache Guacamole | KAN-26 | 📋 Planifié (S27) |

> **Fenêtres de maintenance réseau :** jeudi soir 19h–22h et samedi matin 9h–12h.
> Critère de passage à Phase 3 : VPN SSL opérationnel + accès SSH vm-streaming depuis externe.

---

### Phase 3 - Bases de données et stockage (S18–S25 · Mai–Juin 2026)
**Responsable : Iman Hamdy**
| Tâche | KAN | Statut |
|---|---|---|
| PostgreSQL + MongoDB + Redis (docker-compose) | KAN-18 | ✅ Terminé |
| MinIO S3 storage stack | KAN-18 | ✅ Terminé |

> Critère de passage : `pg_isready` et `redis-cli ping` retournent succès.

---

### Phase 4 - Monitoring et IDS (S22–S27 · Juin–Juillet 2026)
**Responsable : Adrien**
| Tâche | KAN | Statut |
|---|---|---|
| Grafana + Prometheus + Loki + Promtail | KAN-19 | 🔄 En cours |
| Suricata IDS (monitoring-net) | KAN-19 | 📋 Planifié (S25–S27) |
| Dashboards Grafana (infra + Green IT KPIs) | KAN-19 | 📋 Planifié (S26) |

---

### Phase 5 - Services applicatifs (S22–S28 · Juin–Juillet 2026)
**Responsable : Iman Hamdy**
| Tâche | KAN | Statut |
|---|---|---|
| Keycloak IAM + SSO + MFA | - | 📋 Planifié (S22–S27) |
| Vault secrets + PKI | - | 📋 Planifié (S23–S27) |
| Traefik proxy + TLS | - | 📋 Planifié (S23–S26) |
| Jellyfin streaming | - | 📋 Planifié (S24–S28) |

---

### Phase 6 - DevOps, CI/CD et Kubernetes (S20–S28 · Juin–Juillet 2026)
**Responsable : Iman Hamdy**
| Tâche | KAN | Statut |
|---|---|---|
| GitHub Actions CI/CD pipelines | KAN-20 | 📋 Planifié |
| WPA3-Enterprise AP Cisco 2802 | KAN-28 | 📋 Planifié (faible priorité) |
| Déploiement Kubernetes | KAN-10 | 📋 Futur (S27–S28) |

---

### Phase 7 - Documentation continue (S16–S28 · tout le projet)
**Responsable : Tous**
| Livrable | Statut |
|---|---|
| DAT + supplément ITIL/ISO 20000 | ✅ Terminé |
| PCA/PRA | ✅ Terminé |
| Charte informatique | ✅ Terminé |
| Procédure backup/restore | ✅ Terminé |
| Comparatif solutions (TCO) | ✅ Terminé |
| Plan de déploiement (ce document) | ✅ Terminé |
| Green IT & RSE | ✅ Terminé |
| RFCs ITIL | 🔄 En cours (RFC-001 clôturé, RFC-004/005 en cours) |

---

## 4. Suivi d'avancement

| Phase | Prévu | Réalisé | Écart |
|---|---|---|---|
| Phase 1 - Infra Proxmox | S16–S18 | S16–S18 | 0 |
| Phase 2 - Réseau | S16–S22 | S16–S25 (en cours) | +3 semaines |
| Phase 3 - BDD/Stockage | S20–S22 | S18–S25 | En avance |
| Phase 4 - Monitoring | S22–S25 | S22–S27 (en cours) | +2 semaines |
| Phase 5 - Services app | S22–S27 | S22–S28 | Décalé (dépend réseau) |
| Phase 6 - DevOps | S20–S28 | S20–S28 | Conforme |

**Analyse des écarts :** Le retard de Phase 2 (réseau) s'explique par la disponibilité du matériel FortiGate HA livré en S18 au lieu de S16, et la complexité de configuration du switch HP (KAN-7). Ce retard impacte Phase 5 (services applicatifs) qui nécessite un VLAN opérationnel pour les tests de bout en bout.

**Action corrective :** Priorisation de KAN-7 (switch HP) et KAN-23 (VLANs) lors de la semaine S25, avec session de travail dédiée le samedi 28 juin.
