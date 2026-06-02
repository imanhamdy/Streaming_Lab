# Gitflow Guide — Streaming Lab

## Branches

| Branche | Rôle | Accès direct |
|---|---|---|
| `main` | Production stable — livrables/démos | Interdit |
| `develop` | Intégration continue — travail principal | Interdit |
| `feature/*` | Développement d'une fonctionnalité | Oui |

---

## Répartition des branches par personne

| Personne | Branches |
|---|---|
| **P1** | `feature/proxmox-vms` · `feature/iac-devops` |
| **P2** | `feature/docker-stacks` · `feature/bases-de-donnees` · `feature/iam-securite` |
| **P3** | `feature/reseau-securite` · `feature/monitoring-ids` · `feature/stockage-backup` |
| **Tous** | `feature/documentation` |

---

## Workflow quotidien

### 1. Début de session — se synchroniser

```bash
git checkout develop
git pull origin develop
git checkout feature/ma-branche
git rebase develop
```

### 2. Travailler et commiter

```bash
git add .
git commit -m "feat(proxy): add Traefik HTTPS config"
```

### 3. Pousser et ouvrir une PR

```bash
git push origin feature/ma-branche
```

Sur GitHub :
- Ouvrir une **Pull Request** vers `develop`
- Assigner un autre membre pour **review**
- Attendre **1 approval** minimum avant de merger

### 4. Après merge de la PR

```bash
git checkout develop
git pull origin develop
git branch -d feature/ma-branche
```

---

## Convention des messages de commit

```
<type>(<scope>): <description courte>
```

| Type | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `chore` | Tâche technique (config, deps) |
| `docs` | Documentation |
| `ci` | CI/CD, scripts |
| `refactor` | Refactoring sans changement fonctionnel |

**Exemples :**
```
feat(keycloak): add realm config for streaminglab
fix(traefik): correct HTTPS redirect rule
chore(env): update .env.example with Vault vars
docs(dat): add network architecture section
```

---

## Mise en production (merge develop → main)

Uniquement pour les **démos et livrables** :

```bash
git checkout main
git pull origin main
git merge develop --no-ff -m "release: oral intermédiaire v1.0"
git push origin main
```

---

## Schéma des flux

```
main        ────────────────────────────────────● release
                                               /
develop     ──●────●────●────●────●────●──────●
               \  /      \  /      \  /
feature/*   ────●          ●        ●
            docker-stacks  db       monitoring
```

---

## Règles absolues

1. **Ne jamais pusher directement sur `develop` ou `main`**
2. **Toujours passer par une Pull Request**
3. **1 review minimum** avant merge
4. **Jamais de `git push --force`** sur `develop` ou `main`
5. **Rebase avant d'ouvrir une PR** pour éviter les conflits

---

## Travailler avec des branches feature déjà existantes

Si plusieurs personnes travaillent déjà sur des branches longue durée (ex : `feature/*`) :

- **Ne pas créer de nouvelle branche longue durée** tant que possible : préférez de petites branches courtes et ciblées dérivées de `develop`.
- **Stabiliser l'intégration** : mettez en place une cadence régulière (quotidienne ou bi-quotidienne) où chaque propriétaire de branche :
    - fait un `git fetch origin` puis `git rebase origin/develop` (ou `git merge origin/develop` si vous préférez) ;
    - exécute les tests et corrige rapidement les régressions avant de pousser.
- **Conversion progressive** : pour les branches très longues, créez des sous-branches petites (ex : `feature/iam-securite/part-1`) et ouvrez des PRs incrémentales plutôt qu'une PR monolithique.
- **Feature flags** : si une fonctionnalité est incomplète mais doit être intégrée, utilisez des feature flags pour garder `develop` déployable.
- **Draft PRs & communication** : ouvrez des Draft PRs pour signaler le travail en cours ; ajoutez un échéancier et notes dans la description pour synchroniser l'équipe.
- **Propriétaires et responsabilités** : ajoutez un `CODEOWNERS` (ou liste d'assignees) pour chaque dossier critique (`docker/`, `infra/`, `monitoring/`) afin d'obtenir des revues pertinentes rapidement.
- **Stratégie de rattrapage** : lorsqu'une branche longue est prête à être fusionnée :
    1. Mettre à jour la branche avec `develop` et résoudre tous les conflits localement.
    2. Exécuter la suite CI complète et corriger les échecs.
    3. Ouvrir une PR vers `develop` en demandant des reviewers identifiés et en joignant un plan de test.

Ces règles minimisent les conflits et maintiennent `develop` sain même si plusieurs branches longues existent.


## Commandes utiles

```bash
# Voir toutes les branches
git branch -a

# Voir l'état du dépôt
git status

# Voir les derniers commits
git log --oneline --graph --all

# Annuler le dernier commit (avant push)
git reset --soft HEAD~1

# Mettre de côté des modifications non commitées
git stash
git stash pop
```

---

## Résolution de conflits

```bash
# Lors d'un rebase avec conflit :
git status                   # voir les fichiers en conflit
# éditer les fichiers → résoudre les conflits
git add <fichier>
git rebase --continue

# Annuler le rebase si besoin
git rebase --abort
```
