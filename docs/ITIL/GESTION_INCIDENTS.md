# Procédure de Gestion des Incidents (ITIL v4 / ISO 20000)
**Streaming Lab — Ynov Campus B3 INFRA**
Version 1.0 — Juin 2026

---

## 1. Objectif

Ce document définit le processus de gestion des incidents du SI Streaming Lab conformément à **ITIL v4** (pratique "Incident Management") et à la norme **ISO/CEI 20000-1 (clause 8.5)**. L'objectif est de rétablir le service dans les délais définis par les SLA aussi rapidement que possible.

---

## 2. Définitions

| Terme | Définition |
|---|---|
| **Incident** | Interruption non planifiée ou dégradation d'un service IT |
| **Incident majeur** | Incident à fort impact nécessitant une cellule de crise |
| **Problème** | Cause sous-jacente d'un ou plusieurs incidents |
| **Workaround** | Solution de contournement temporaire permettant de restaurer le service |
| **RCA** | Root Cause Analysis — analyse de cause racine post-incident |

---

## 3. Classification des incidents

### 3.1 Matrice Impact / Urgence

|  | **Urgence 1 — Critique** | **Urgence 2 — Haute** | **Urgence 3 — Moyenne** | **Urgence 4 — Faible** |
|---|---|---|---|---|
| **Impact 1 — Élevé** | 🔴 **P1 — Critique** | 🔴 **P1 — Critique** | 🟠 **P2 — Haute** | 🟡 **P3 — Moyenne** |
| **Impact 2 — Moyen** | 🔴 **P1 — Critique** | 🟠 **P2 — Haute** | 🟡 **P3 — Moyenne** | 🟢 **P4 — Faible** |
| **Impact 3 — Faible** | 🟠 **P2 — Haute** | 🟡 **P3 — Moyenne** | 🟢 **P4 — Faible** | 🟢 **P4 — Faible** |

### 3.2 Délais de traitement (SLA)

| Priorité | Délai de prise en charge | Délai de résolution | Notification équipe |
|---|---|---|---|
| 🔴 **P1 — Critique** | 15 min | 2 heures | Immédiate (tous membres) |
| 🟠 **P2 — Haute** | 30 min | 4 heures | Dans l'heure |
| 🟡 **P3 — Moyenne** | 2 heures | 24 heures | Journalière |
| 🟢 **P4 — Faible** | 8 heures | 72 heures | Hebdomadaire |

### 3.3 Exemples de classification

| Incident | Impact | Urgence | Priorité |
|---|---|---|---|
| Jellyfin inaccessible (service down) | Élevé | Critique | 🔴 P1 |
| Keycloak SSO en erreur — aucun login possible | Élevé | Critique | 🔴 P1 |
| Grafana inaccessible — monitoring aveugle | Moyen | Haute | 🟠 P2 |
| Alerte Suricata — tentative intrusion | Élevé | Haute | 🟠 P2 |
| PostgreSQL connexions saturées | Moyen | Haute | 🟠 P2 |
| Sauvegarde Veeam en échec | Élevé | Moyenne | 🟡 P3 |
| Redis latence élevée (>100ms) | Faible | Faible | 🟢 P4 |
| Certificat TLS expirant dans 7 jours | Faible | Faible | 🟢 P4 |

---

## 4. Processus de gestion d'un incident

```
Détection
(Suricata / Grafana alert / utilisateur)
         │
         ▼
   Enregistrement
   (issue GitHub + horodatage)
         │
         ▼
   Classification
   (Impact + Urgence → Priorité P1..P4)
         │
         ▼
   Diagnostic initial
   (logs Loki, docker ps, Grafana)
         │
    Résolu ?
   ┌──────┴──────┐
  Oui           Non
   │             │
   │     Escalade niveau supérieur
   │     (P1 → cellule de crise)
   │             │
   │             ▼
   │     Workaround appliqué
   │     (service restauré)
   │             │
   └──────┬──────┘
          │
          ▼
   Résolution définitive
   (correctif déployé via RFC si changement)
          │
          ▼
   Clôture incident
   (documentation + notification)
          │
          ▼
   Post-mortem (si P1/P2)
   → création ticket Problème
```

---

## 5. Niveaux de support

| Niveau | Équipe | Périmètre |
|---|---|---|
| **N1** | Tous membres | Vérification basique : `docker ps`, redémarrage service, consultation Grafana |
| **N2** | Admin concerné | Analyse logs Loki, diagnostic réseau, reconfiguration service |
| **N3** | Admin principal | Restauration VM, intervention Proxmox, rollback infra |

---

## 6. Outils de détection et diagnostic

| Outil | Usage | Accès |
|---|---|---|
| **Grafana** | Alertes visuelles, état des services | https://grafana.duoowatch.com |
| **Loki** | Analyse des logs applicatifs et système | Via Grafana (datasource Loki) |
| **Prometheus** | Métriques CPU/RAM/réseau | http://192.168.40.10:9090 (VPN) |
| **Suricata** | Alertes de sécurité réseau | Logs dans Loki (job: suricata) |
| **docker ps / logs** | État et logs des containers | SSH sur vm-streaming (VPN requis) |

---

## 7. Registre des incidents

| INC ID | Date | Service | Description | Priorité | Durée résolution | Statut | RCA |
|---|---|---|---|---|---|---|---|
| INC-001 | 23/06/2026 | Jellyfin | Erreur syntaxe docker-compose — service non démarrable | 🔴 P1 | 10 min | Clôturé ✅ | Syntaxe YAML invalide (restart + hostname sur même ligne) — corrigé RFC-003 |
| INC-002 | | | | | | | |

---

## 8. Post-mortem — Template

Pour tout incident P1 ou P2, un post-mortem est rédigé dans les **24h** suivant la clôture :

```
## Post-mortem INC-XXX — [Titre]

**Date :** JJ/MM/AAAA
**Durée d'impact :** X heures X minutes
**Services affectés :** [liste]
**Priorité :** P1 / P2

### Chronologie
- HH:MM — Détection (par qui / quel outil)
- HH:MM — Prise en charge (par qui)
- HH:MM — Workaround appliqué
- HH:MM — Résolution définitive
- HH:MM — Clôture

### Cause racine (RCA)
[Description précise de la cause]

### Impact
[Nombre d'utilisateurs affectés, services dégradés, durée]

### Actions correctives
| Action | Responsable | Délai | Statut |
|---|---|---|---|
| | | | |

### Leçons apprises
[Ce qui aurait pu éviter l'incident, ce qui a bien fonctionné]
```

---

## 9. Lien Incidents → Problèmes

Tout incident récurrent (≥ 2 occurrences en 30 jours) ou incident P1 donne lieu à l'ouverture d'un **ticket Problème** dans le Jira (KAN board) pour analyse de la cause racine et mise en place d'une solution définitive, conformément à la pratique ITIL "Problem Management".
