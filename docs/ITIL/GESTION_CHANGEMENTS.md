# Procédure de Gestion des Changements (ITIL v4)
**Streaming Lab — Ynov Campus B3 INFRA**
Version 1.0 — Juin 2026

---

## 1. Objectif

Cette procédure définit le processus de gestion des changements appliqué au SI Streaming Lab, conformément aux pratiques ITIL v4 et aux exigences de la norme **ISO/CEI 20000-1 (clause 8.7)**. Elle garantit que toute modification du SI est évaluée, autorisée, planifiée et documentée avant mise en production.

---

## 2. Types de changements

| Type | Définition | Exemples dans le projet | Autorisation requise |
|---|---|---|---|
| **Standard** | Changement pré-approuvé, risque faible, répétable | Mise à jour image Docker, ajout variable `.env` | Aucune — procédure documentée suffit |
| **Normal** | Changement planifié, nécessite évaluation et RFC | Ajout d'un nouveau service Docker, modification VLAN | CAB (Change Advisory Board) |
| **Urgent** | Changement non planifié pour restaurer un service | Rollback après incident critique | Validation a posteriori par le responsable |

---

## 3. Processus de changement normal (RFC)

```
Demande de changement (RFC)
        │
        ▼
  Évaluation des risques
  (impact, urgence, rollback)
        │
        ▼
  Revue CAB (équipe projet)
  → Approbation ou rejet
        │
     Approuvé?
    ┌──┴──┐
   Non   Oui
    │     │
  Rejet  Planification
    │     │
    │     ▼
    │  Implémentation
    │  (feature branch → PR → merge develop)
    │     │
    │     ▼
    │  Tests & validation
    │     │
    │     ▼
    │  Mise en production
    │  (merge main → make up-<stack>)
    │     │
    └─────▼
       Clôture RFC + documentation
```

---

## 4. Rôles et responsabilités

| Rôle | Personne | Responsabilité |
|---|---|---|
| **Change Initiator** | Tout membre de l'équipe | Rédiger et soumettre la RFC |
| **Change Manager** | Iman Hamdy | Évaluer, planifier, coordonner |
| **CAB** (Change Advisory Board) | Équipe projet complète | Approuver/rejeter les changements normaux |
| **Technicien** | Selon compétence | Implémenter le changement |

---

## 5. Critères d'évaluation d'une RFC

Chaque RFC est évaluée selon les critères suivants :

| Critère | Questions à se poser |
|---|---|
| **Impact** | Combien de services/utilisateurs sont affectés ? |
| **Urgence** | Quel est le délai acceptable avant implémentation ? |
| **Risque** | Quelle est la probabilité d'échec et ses conséquences ? |
| **Rollback** | Comment revenir à l'état précédent en cas d'échec ? |
| **Fenêtre** | Quel est le créneau de maintenance optimal ? |

---

## 6. Matrice impact / urgence

|  | **Urgence faible** | **Urgence moyenne** | **Urgence haute** |
|---|---|---|---|
| **Impact faible** | Planifié (J+14) | Planifié (J+7) | Planifié (J+3) |
| **Impact moyen** | Planifié (J+7) | Planifié (J+3) | Changement urgent |
| **Impact élevé** | Planifié (J+3) | Changement urgent | Changement urgent |

---

## 7. Lien avec Git flow

Le processus ITIL de gestion des changements est **nativement implémenté** dans le workflow Git du projet :

| Étape ITIL | Équivalent Git |
|---|---|
| Soumission RFC | Ouverture d'une issue GitHub |
| Approbation CAB | Review et approval de la Pull Request |
| Implémentation | Commits sur `feature/*` |
| Tests | CI/CD GitHub Actions (`.github/workflows/`) |
| Mise en production | Merge `develop` → `main` + `make up-<stack>` |
| Rollback plan | `git revert` ou `git checkout` vers tag précédent |

---

## 8. Registre des changements

| RFC ID | Date | Type | Description | Statut | Implémenté par |
|---|---|---|---|---|---|
| RFC-001 | 2026-06-23 | Normal | Ajout stack MinIO (storage-net) | Clôturé ✅ | Iman H. |
| RFC-002 | 2026-06-23 | Normal | Migration credentials vers docker/.env partagé | Clôturé ✅ | Iman H. |
| RFC-003 | 2026-06-23 | Standard | Fix syntaxe docker-compose Jellyfin | Clôturé ✅ | Iman H. |
| RFC-004 | En cours | Normal | Déploiement stack monitoring (Grafana/Prometheus/Loki/Suricata) | En cours 🔄 | Adrien |
| RFC-005 | Planifié | Normal | Configuration Cloudflare Zero Trust Tunnel | Planifié 📋 | Quentin |
