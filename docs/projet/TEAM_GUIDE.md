# Team Guide — Streaming Lab

## Contexte

- **3 développeurs** travaillant depuis leurs PCs locaux
- **1 VM de production** : `vm-streaming` (192.168.10.2) — accessible via VPN FortiClient (192.168.100.100)
- **GitHub** : point de synchronisation commun

---

## Schéma global

```
PCs locaux              GitHub                  vm-streaming
──────────              ──────────              ────────────
P1 → feature/*          feature/* → PR
P2 → feature/*     →    → develop   → git pull → tester
P3 → feature/*          → main      → git pull → démo/livrable
```

---

## 1. Setup initial (une fois par personne)

### Cloner le repo

```bash
git clone https://github.com/imanhamdy/Streaming_Lab.git
cd Streaming_Lab
```

### Configurer son identité git

```bash
git config user.name "Ton Prénom"
git config user.email "ton.email@ynov.com"
```

### Récupérer toutes les branches

```bash
git fetch --all
git checkout develop
```

---

## 2. Répartition des branches

| Personne | Branches |
|---|---|
| **P1** | `feature/proxmox-vms` · `feature/iac-devops` |
| **P2** | `feature/docker-stacks` · `feature/bases-de-donnees` · `feature/iam-securite` |
| **P3** | `feature/reseau-securite` · `feature/monitoring-ids` · `feature/stockage-backup` |
| **Tous** | `feature/documentation` |

---

## 3. Workflow quotidien

### Début de session — toujours se synchroniser

```bash
git checkout develop
git pull origin develop
git checkout feature/ma-branche
git rebase develop
```

### Coder et commiter

```bash
git add .
git commit -m "feat(scope): description courte"
```

**Convention des commits :**

| Type | Usage |
|---|---|
| `feat` | Nouvelle fonctionnalité |
| `fix` | Correction de bug |
| `chore` | Config, dépendances |
| `docs` | Documentation |
| `ci` | Scripts, CI/CD |

**Exemples :**
```
feat(traefik): add HTTPS with Let's Encrypt
fix(postgres): correct volume mount path
docs(dat): add network architecture diagram
chore(env): update .env.example
```

### Pousser et ouvrir une PR

```bash
git push origin feature/ma-branche
```

Sur GitHub :
1. **New Pull Request** → base : `develop`
2. Décrire ce qui a été fait
3. Assigner un autre membre pour review
4. Attendre **1 approval** avant de merger

---

## 4. Voir l'avancement sur la VM

Après chaque merge dans `develop`, se connecter à la VM et tirer les changements :

```bash
# Connexion à la VM (via VPN actif)
ssh principal@192.168.10.2

# Sur la VM
git checkout develop
git pull origin develop
make up-<stack>
```

**Exemples :**
```bash
make up-proxy        # démarrer Traefik
make up-databases    # démarrer PostgreSQL + MongoDB + Redis
make up-keycloak     # démarrer Keycloak
make up-jellyfin     # démarrer Jellyfin
make logs-proxy      # voir les logs Traefik
make ps              # voir tous les conteneurs actifs
```

---

## 5. Mise en production (démo / livrable)

Quand `develop` est stable et testé sur la VM :

1. Ouvrir une PR `develop` → `main` sur GitHub
2. **2 approvals** requis
3. Après merge, sur la VM :

```bash
git checkout main
git pull origin main
make up
```

---

## 6. Règles absolues

1. **Ne jamais pusher directement** sur `develop` ou `main`
2. **Toujours passer par une PR**
3. **Se synchroniser avec develop** avant de commencer à coder
4. **Jamais de `git push --force`** sur `develop` ou `main`
5. **Tester sur la VM depuis `develop`**, pas depuis une feature branch

---

## 7. Ordre de développement conseillé

```
1. feature/proxmox-vms        → infra Proxmox / VMs
2. feature/reseau-securite    → VLANs, FortiGate, DNS
3. feature/docker-stacks      → Traefik, Jellyfin, Keycloak
4. feature/bases-de-donnees   → PostgreSQL, MongoDB, Redis
5. feature/iam-securite       → Keycloak config, Vault
6. feature/stockage-backup    → MinIO, sauvegardes
7. feature/monitoring-ids     → Grafana, Prometheus, Loki, Suricata
8. feature/iac-devops         → Ansible, CI/CD
9. feature/documentation      → DAT, PCA/PRA, UML
```

---

## 8. Commandes git utiles

```bash
# Voir toutes les branches
git branch -a

# Voir l'historique visuel
git log --oneline --graph --all

# Mettre de côté des modifs non commitées
git stash
git stash pop

# Annuler le dernier commit (avant push)
git reset --soft HEAD~1

# Résoudre un conflit lors d'un rebase
git status                  # voir les fichiers en conflit
# éditer les fichiers
git add <fichier>
git rebase --continue
# ou annuler
git rebase --abort
```

---

## 9. Accès à la VM

```bash
# Prérequis : VPN FortiClient connecté (192.168.100.100)
ssh principal@192.168.10.2
```

> Demander le mot de passe sudo à P1 si nécessaire.
