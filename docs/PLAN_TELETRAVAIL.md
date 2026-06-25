# Plan de Télétravail Sécurisé - Streaming Lab
**Ynov Campus B3 INFRA - BC03 Compétences 6, 15 & 16**
Version 1.0 - Juin 2026

---

## 1. Objectif

Ce document définit la chaîne d'approvisionnement, le dimensionnement et les mesures de sécurité nécessaires pour garantir la continuité du service Streaming Lab en situation de **télétravail massif** (100% de l'équipe à distance).

---

## 2. Contexte et périmètre

L'équipe projet est composée de **3 membres** travaillant depuis des postes locaux distincts. Le SI est hébergé sur site (Ynov Campus). En situation de télétravail, tous les accès passent par le réseau public internet.

**Scénario cible :** 3 administrateurs en télétravail simultané + accès utilisateurs Jellyfin maintenus.

---

## 3. Architecture d'accès en télétravail

```
Domicile (Admin)                   Ynov Campus (On-Premise)
─────────────────                  ──────────────────────────
PC portable                        FortiGate HA (VIP 192.168.1.20)
    │                                      │
    ├──[FortiClient VPN SSL]──────────────►│ VLAN 90 (mgmt)
    │   + MFA (TOTP)                       │
    │                                      ▼
    │                              vm-streaming (192.168.20.10)
    │                                      │
    └──[Cloudflare Zero Trust]────────────►Traefik
        (navigateur, sans client)          │
                                      Services (Jellyfin, Grafana...)
```

**Deux modes d'accès selon le profil :**

| Profil | Méthode | Accès autorisé |
|---|---|---|
| Administrateur | FortiClient VPN SSL + MFA | SSH, Proxmox, Grafana, tous les services |
| Utilisateur streaming | Cloudflare Zero Trust (navigateur) | Jellyfin uniquement via HTTPS |

---

## 4. Dimensionnement VPN (Compétence 15)

### 4.1 Capacité concentrateur VPN FortiGate

| Paramètre | Valeur |
|---|---|
| Modèle | FortiGate 60F HA |
| Tunnels VPN SSL simultanés max | 200 |
| Besoins actuels (3 admins) | 3 tunnels |
| Bande passante VPN SSL | 900 Mbps |
| Consommation estimée par admin | ~10 Mbps (SSH + outils) |
| **Marge disponible** | **>95%** - largement suffisant |

### 4.2 Bande passante internet requise

| Flux | Bande passante |
|---|---|
| 3 admins VPN simultanés | 3 × 10 Mbps = 30 Mbps montant |
| Utilisateurs Jellyfin (720p) | ~5 Mbps/utilisateur |
| **Lien internet minimum recommandé** | **100 Mbps symétrique** |

---

## 5. Équipements et licences requis (Compétence 15)

### 5.1 Postes administrateurs

| Élément | Spécification | Quantité | Statut |
|---|---|---|---|
| PC portable | 16 Go RAM, SSD 512 Go, chiffrement BitLocker/LUKS | 3 | Disponible (PCs personnels) |
| FortiClient VPN | Licence incluse FortiGate | 3 | ✅ Disponible |
| Authenticator MFA | FreeOTP / Google Authenticator (gratuit) | 3 | ✅ Disponible |
| Accès GitHub | Compte individuel + 2FA activé | 3 | ✅ Disponible |

### 5.2 Infrastructure serveur (aucun changement requis)

Le SI étant déjà entièrement hébergé on-premise avec accès VPN, **aucun équipement supplémentaire** n'est nécessaire pour basculer en télétravail complet. C'est un avantage direct de l'architecture choisie.

### 5.3 Fournisseurs identifiés

| Besoin | Fournisseur | Délai appro. |
|---|---|---|
| Licences FortiClient supplémentaires | Fortinet / revendeur agréé | 48h (licence numérique) |
| PC portables de secours | Dell France / LDLC Pro | 5–10 jours ouvrés |
| Tokens YubiKey (MFA physique) | Yubico.com | 3–5 jours |
| Bande passante internet augmentée | FAI actuel Ynov | 5–15 jours |

---

## 6. Politique de sécurité télétravail (Compétence 6)

### 6.1 Règles obligatoires pour les admins en télétravail

- [ ] **VPN FortiClient actif** avant tout accès aux ressources internes
- [ ] **MFA activé** sur le compte VPN et sur GitHub
- [ ] **Chiffrement du poste** activé (BitLocker Windows / LUKS Linux)
- [ ] **Réseau domestique sécurisé** : WPA2/WPA3, mot de passe fort, VLAN si possible
- [ ] **Écran verrouillé** dès inactivité (timeout 5 min)
- [ ] **Aucun travail sur réseau public** sans VPN actif
- [ ] **Pas de données sensibles** stockées localement non chiffrées

### 6.2 Gestion des terminaux mobiles (MDM - Compétence 6)

En l'absence de solution MDM dédiée (hors scope budget), les appareils mobiles sont gérés via **politique FortiClient** :

| Contrôle | Implémentation |
|---|---|
| Authentification mobile | FortiClient mobile (iOS/Android) + MFA |
| Accès VPN mobile | Identique aux postes fixes |
| Vérification posture | FortiClient vérifie OS à jour avant connexion |
| Révocation accès | Suppression compte VPN dans FortiGate immédiate |
| Cloisonnement pro/perso | VPN crée un tunnel dédié isolé du réseau perso |

> **Note :** Pour un déploiement MDM complet, Microsoft Intune (inclus M365 Business) serait la solution recommandée. Budget estimé : ~6 €/utilisateur/mois.

---

## 7. Procédure de basculement en télétravail massif (Compétence 16)

### Déclenchement (J0 - décision de basculement)

| Étape | Action | Responsable | Délai |
|---|---|---|---|
| 1 | Notifier tous les membres de l'équipe | Iman H. | < 1h |
| 2 | Vérifier que tous ont FortiClient installé et configuré | Iman H. | < 2h |
| 3 | Vérifier capacité VPN (nb tunnels dispo) | Quentin | < 1h |
| 4 | Activer monitoring renforcé (alertes Grafana) | Adrien | < 2h |
| 5 | Confirmer accès SSH depuis domicile pour chaque admin | Tous | < 4h |
| **Total** | **Basculement complet** | | **< 4 heures** |

### Continuité de service utilisateurs

Les utilisateurs Jellyfin **ne sont pas impactés** par le télétravail de l'équipe : le service continue de fonctionner via Cloudflare Zero Trust indépendamment de la présence physique des admins.

---

## 8. Tests de basculement

| Test | Fréquence | Dernière exécution | Résultat |
|---|---|---|---|
| Connexion VPN depuis domicile (3 admins) | Mensuel | Juin 2026 | ✅ Succès |
| SSH vm-streaming depuis VPN | Mensuel | Juin 2026 | ✅ Succès |
| Accès Proxmox depuis VPN | Trimestriel | Juin 2026 | ✅ Succès |
| Déploiement stack Docker depuis domicile | Trimestriel | Juin 2026 | ✅ Succès |
