# Charte Informatique - Streaming Lab
**Ynov Campus B3 INFRA - Projet Streaming Lab**
Version 1.0 - Juin 2026

---

## 1. Objet et périmètre

La présente charte définit les règles d'utilisation, de sécurité et de bon usage du Système d'Information (SI) du projet Streaming Lab. Elle s'applique à l'ensemble des membres de l'équipe projet (administrateurs systèmes, développeurs, utilisateurs de la plateforme) accédant aux ressources informatiques, qu'elles soient physiques ou virtuelles.

Le SI concerné comprend :
- Le serveur physique DELL T140 hébergeant Proxmox VE 8
- Les machines virtuelles : `vm-streaming`, `vm-dns`, `vm-backup`
- Les stacks Docker déployées sur `vm-streaming`
- L'infrastructure réseau : FortiGate HA, Cisco Catalyst C3650, VLANs
- Les accès distants : VPN SSL FortiClient, Cloudflare Zero Trust Tunnel

---

## 2. Principes généraux de sécurité

### 2.1 Confidentialité
- Aucun mot de passe, secret ou credential ne doit être commité dans le dépôt Git.
- Toutes les données sensibles sont stockées dans des fichiers `.env` exclus du versionnage (`.gitignore`) ou dans HashiCorp Vault.
- L'accès aux données utilisateurs (PostgreSQL, MongoDB) est restreint aux services applicatifs via des réseaux Docker isolés (`db-net`).

### 2.2 Intégrité
- Tout changement d'infrastructure passe par une Pull Request revue par au moins un autre membre de l'équipe avant merge.
- Les configurations critiques (FortiGate, Keycloak, Vault) sont versionnées dans Git et soumises aux mêmes règles de review.
- Les sauvegardes sont chiffrées et leur intégrité est vérifiée à intervalle régulier (voir procédure de restauration).

### 2.3 Disponibilité
- La haute disponibilité est assurée par : FortiGate HA (VIP 192.168.1.20), Veeam B&R sur `vm-backup`, et la politique de restart Docker (`unless-stopped`).
- Les objectifs de disponibilité cibles sont définis dans le PCA/PRA.

---

## 3. Règles d'accès et d'authentification

| Ressource | Méthode d'accès | Authentification requise |
|---|---|---|
| vm-streaming (SSH) | VPN SSL FortiClient actif | Clé SSH + MFA |
| Jellyfin (streaming) | HTTPS via Traefik | Keycloak SSO |
| Grafana (monitoring) | HTTPS via Traefik | Compte local + MFA |
| MinIO (stockage S3) | HTTPS via Traefik | Compte MinIO |
| Vault (secrets) | HTTPS via Traefik | Token Vault / AppRole |
| Proxmox VE | HTTPS 192.168.90.50:8006 | Compte local (réseau interne uniquement) |
| FortiGate | HTTPS 192.168.1.20 | Admin local (réseau interne uniquement) |

### 3.1 Politique de mots de passe
- Longueur minimale : **12 caractères**
- Composition : majuscules, minuscules, chiffres, caractères spéciaux
- Rotation : tous les **90 jours** pour les comptes à privilèges
- Interdiction de réutiliser les 5 derniers mots de passe

### 3.2 Gestion des accès (IAM)
- Les identités sont centralisées dans **Keycloak** (SSO, MFA, fédération LDAP)
- Le principe du **moindre privilège** s'applique : chaque service n'accède qu'au réseau Docker dont il a besoin
- Les comptes administrateurs sont distincts des comptes utilisateurs
- Tout accès distant passe obligatoirement par le **VPN SSL FortiClient avec MFA**

---

## 4. Segmentation réseau et isolation

La politique de sécurité réseau repose sur une segmentation stricte par VLANs et réseaux Docker :

| VLAN / Réseau | Périmètre | Accès autorisé |
|---|---|---|
| VLAN 20 - `streaming-net` | Traefik, Jellyfin, Keycloak, Vault | Internet → Traefik uniquement |
| VLAN 20 - `db-net` | PostgreSQL, MongoDB, Redis | Services applicatifs uniquement |
| VLAN 20 - `monitoring-net` | Grafana, Prometheus, Loki, Suricata | Admins (VPN) |
| VLAN 20 - `storage-net` | MinIO | Services applicatifs + admins (VPN) |
| VLAN 110 | vm-dns | Réseau interne uniquement |
| VLAN 140 | vm-backup | Réseau interne uniquement |

Les règles FortiGate interdisent tout flux inter-VLAN non explicitement autorisé.

---

## 5. Politique de sauvegarde

- Les VMs Proxmox sont sauvegardées quotidiennement via **Veeam B&R** sur `vm-backup`
- Les sauvegardes sont **chiffrées en AES-256** lors du transfert réseau
- La rétention est de **7 jours** (sauvegardes quotidiennes) + **4 semaines** (sauvegardes hebdomadaires)
- Un **test de restauration** est réalisé mensuellement (voir `docs/PROCEDURE_BACKUP_RESTORE.md`)

---

## 6. Détection des incidents et réponse

- **Suricata** (IDS) surveille le trafic réseau en temps réel sur `monitoring-net`
- Les alertes sont centralisées dans **Loki** et visualisées dans **Grafana**
- Tout incident de sécurité identifié est traité selon la procédure :
  1. Identification et isolation du composant affecté
  2. Analyse des logs (Loki + Grafana)
  3. Application du correctif
  4. Documentation de l'incident et des actions correctives
  5. Communication à l'équipe

---

## 7. Règles d'usage des ressources

- Les ressources du SI (CPU, RAM, stockage) sont exclusivement destinées aux besoins du projet
- Il est interdit d'installer des logiciels non validés sur les VMs
- Tout accès aux données utilisateurs à des fins autres que l'administration technique est interdit
- Les logs d'accès sont conservés **6 mois** conformément aux recommandations CNIL

---

## 8. Responsabilités

| Rôle | Responsabilités |
|---|---|
| Administrateur principal (P1) | Proxmox, VMs, accès sudo, gestion des clés SSH |
| Administrateur réseau (P2) | FortiGate, VLANs, VPN, FortiClient |
| Administrateur monitoring (P3) | Grafana, Prometheus, Loki, Suricata, alertes |
| Tous les membres | Respect de la présente charte, signalement des incidents |

---

## 9. Sanctions

Tout manquement aux règles de la présente charte (partage de credentials, push direct sur `main`, accès non autorisé) entraîne une révision immédiate des droits d'accès et un signalement au responsable pédagogique.

---

## 10. Entrée en vigueur

La présente charte entre en vigueur à compter de sa publication dans le dépôt Git du projet. Elle est révisée à chaque évolution majeure de l'infrastructure.

**Signataires :** Équipe Streaming Lab - Ynov Campus B3 INFRA - Juin 2026
