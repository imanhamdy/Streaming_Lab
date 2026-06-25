# Analyse de Risques — Streaming Lab
**Ynov Campus B3 INFRA — BC03 Compétence 1**
Méthode : ISO 27005 / inspiré EBIOS Risk Manager
Version 1.0 — Juin 2026

---

## 1. Objectif et périmètre

Ce document identifie, évalue et priorise les risques de sécurité pesant sur le SI Streaming Lab afin de permettre aux décideurs de définir et ajuster la politique de sécurité.

**Périmètre couvert :**
- Serveur physique DELL T140 (Proxmox VE 8)
- VMs : vm-streaming, vm-dns, vm-backup
- Stacks Docker : Traefik, Jellyfin, Keycloak, Vault, BDD, MinIO, Monitoring
- Infrastructure réseau : FortiGate HA, Cisco C3650, VLANs
- Accès distants : VPN SSL FortiClient, Cloudflare Zero Trust

---

## 2. Inventaire des biens sensibles (actifs)

| ID | Bien | Type | Sensibilité |
|---|---|---|---|
| A01 | Données utilisateurs Jellyfin (comptes, historique) | Données | 🔴 Haute |
| A02 | Credentials stockés dans Vault | Données | 🔴 Haute |
| A03 | Base PostgreSQL (metadata utilisateurs) | Données | 🔴 Haute |
| A04 | Fichiers médias (MinIO) | Données | 🟡 Moyenne |
| A05 | Logs système et applicatifs (Loki) | Données | 🟡 Moyenne |
| A06 | vm-streaming (Docker Engine) | Système | 🔴 Haute |
| A07 | Keycloak (IdP SSO) | Service | 🔴 Haute |
| A08 | FortiGate HA (firewall) | Réseau | 🔴 Haute |
| A09 | vm-backup + Veeam | Système | 🔴 Haute |
| A10 | Certificats TLS (Let's Encrypt) | Données | 🟡 Moyenne |
| A11 | Dépôt Git (code IaC) | Données | 🟡 Moyenne |
| A12 | Accès SSH vm-streaming | Accès | 🔴 Haute |

---

## 3. Identification des menaces

| ID | Menace | Source | Bien(s) ciblé(s) |
|---|---|---|---|
| M01 | Attaque par force brute SSH | Externe | A12 |
| M02 | Ransomware chiffrant les VMs | Externe | A06, A03, A04 |
| M03 | Compromission credentials (`.env` exposé) | Interne/Externe | A02, A03 |
| M04 | Faille dans image Docker (CVE) | Externe | A06, A07 |
| M05 | Panne matérielle DELL T140 | Physique | A06, A07, A08 |
| M06 | Intrusion réseau inter-VLAN | Externe | A03, A02 |
| M07 | Déni de service (DDoS) sur Traefik | Externe | A07, A06 |
| M08 | Perte/vol de sauvegardes non chiffrées | Interne | A09 |
| M09 | Expiration certificat TLS non détectée | Interne | A10 |
| M10 | Compromission compte admin Keycloak | Interne/Externe | A07, A01 |
| M11 | Push accidentel de secrets sur Git | Interne | A11, A02 |
| M12 | Attaque sur supply chain (image Docker malveillante) | Externe | A06 |

---

## 4. Évaluation des risques (Probabilité × Impact)

**Échelle :**
- Probabilité : 1 (très faible) → 4 (quasi-certaine)
- Impact : 1 (négligeable) → 4 (catastrophique)
- Criticité = Probabilité × Impact → 1–4 : Faible | 5–8 : Moyen | 9–12 : Élevé | 13–16 : Critique

| ID | Risque | Probabilité | Impact | Criticité | Niveau |
|---|---|---|---|---|---|
| R01 | Brute force SSH | 3 | 4 | **12** | 🔴 Élevé |
| R02 | Ransomware VMs | 2 | 4 | **8** | 🟠 Moyen |
| R03 | Credentials exposés dans Git | 2 | 4 | **8** | 🟠 Moyen |
| R04 | CVE image Docker exploitée | 3 | 3 | **9** | 🔴 Élevé |
| R05 | Panne matérielle serveur | 2 | 4 | **8** | 🟠 Moyen |
| R06 | Intrusion inter-VLAN | 2 | 4 | **8** | 🟠 Moyen |
| R07 | DDoS sur Traefik | 2 | 3 | **6** | 🟠 Moyen |
| R08 | Sauvegarde non chiffrée interceptée | 1 | 4 | **4** | 🟡 Faible |
| R09 | Certificat TLS expiré | 3 | 3 | **9** | 🔴 Élevé |
| R10 | Compromission compte admin Keycloak | 2 | 4 | **8** | 🟠 Moyen |
| R11 | Secret pushé sur GitHub | 2 | 4 | **8** | 🟠 Moyen |
| R12 | Image Docker malveillante | 1 | 4 | **4** | 🟡 Faible |

---

## 5. Matrice de risques

```
Impact
  4 │ R08  R05,R06,R10,R11  R01,R02,R03  
    │      R02              
  3 │      R07              R04,R09      
    │                                    
  2 │                                    
    │                                    
  1 │      R12                           
    └──────────────────────────────────▶
         1         2         3         4
                                  Probabilité

🟡 Faible (1–4)   🟠 Moyen (5–8)   🔴 Élevé (9–12)   🚨 Critique (13–16)
```

---

## 6. Plan de traitement des risques

| Risque | Traitement | Mesure mise en œuvre | Responsable | Statut |
|---|---|---|---|---|
| R01 — Brute force SSH | Réduction | Fail2ban + clé SSH uniquement + VPN requis avant SSH | Iman H. | ✅ En place |
| R02 — Ransomware | Réduction + Transfert | Veeam B&R quotidien, isolation VLAN, pas d'accès internet direct VMs | Quentin | ✅ En place |
| R03 — Credentials Git | Réduction | `.gitignore` + Vault + `.env.example` sans valeurs | Iman H. | ✅ En place |
| R04 — CVE Docker | Réduction | Watchtower (mises à jour auto) + images officielles uniquement | Adrien | 🔄 En cours |
| R05 — Panne matérielle | Transfert | Veeam B&R + RTO 4h documenté | Quentin | ✅ En place |
| R06 — Intrusion VLAN | Réduction | Règles FortiGate deny-all inter-VLAN + réseaux Docker isolés | Quentin | 🔄 En cours |
| R07 — DDoS | Réduction | Cloudflare Zero Trust (rate limiting, WAF) | Quentin | 📋 Planifié |
| R08 — Backup intercepté | Réduction | Veeam AES-256 chiffrement activé | Quentin | ✅ En place |
| R09 — Certificat expiré | Réduction | Let's Encrypt renouvellement auto via Traefik + alerte Grafana J-30 | Iman H. | ✅ En place |
| R10 — Admin Keycloak compromis | Réduction | MFA obligatoire compte admin + rotation password 90j | Iman H. | ✅ En place |
| R11 — Secret sur Git | Réduction | `.gitignore` + pre-commit hook (git-secrets) | Iman H. | 📋 Planifié |
| R12 — Supply chain Docker | Réduction | Images officielles uniquement (Docker Hub verified) + Watchtower | Adrien | 🔄 En cours |

---

## 7. Risques résiduels acceptés

| Risque | Justification d'acceptation |
|---|---|
| R08 — Sauvegarde interceptée | AES-256 activé — risque résiduel négligeable |
| R12 — Supply chain | Images officielles uniquement — risque inhérent acceptable en contexte pédagogique |
| R07 — DDoS | Cloudflare Zero Trust planifié — acceptable jusqu'à mise en production |

---

## 8. Révision

Cette analyse de risques est révisée :
- À chaque changement majeur d'architecture (nouvelle VM, nouveau service)
- Après tout incident de sécurité classé P1 ou P2
- Trimestriellement en phase de production
