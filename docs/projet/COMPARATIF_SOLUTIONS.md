# Comparatif des Solutions Techniques - Justification des Choix
**Streaming Lab - Ynov Campus B3 INFRA**
Version 1.0 - Juin 2026

> Document répondant à la Compétence 3 (BC02) : comparaison de solutions
> avec analyse TCO/ROI et recommandations argumentées.

---

## 1. Hyperviseur - Proxmox VE vs VMware ESXi vs Microsoft Hyper-V

| Critère | **Proxmox VE 8** ✅ | VMware ESXi 8 | Hyper-V 2022 |
|---|---|---|---|
| **Licence** | Gratuit (open-source) | ~4 500 €/socket/an | Inclus Windows Server (~900 €) |
| **TCO 3 ans (1 serveur)** | **0 €** | ~13 500 € | ~2 700 € |
| **Interface web** | Oui (natif) | Oui (vSphere) | Oui (partiel) |
| **Support KVM + LXC** | ✅ Oui | ❌ Non | ❌ Non |
| **Sauvegarde intégrée** | Oui (via Vzdump) | Payant (vSphere) | Limité |
| **Clustering HA** | Oui (Corosync) | Oui (vSphere HA) | Oui |
| **Communauté / docs** | Large | Large (payant) | Moyenne |
| **Courbe d'apprentissage** | Faible | Faible | Moyenne |

**Recommandation : Proxmox VE 8**
**Économie réalisée vs VMware : 13 500 € sur 3 ans.** Proxmox offre toutes les fonctionnalités nécessaires (KVM, clustering, snapshots, Veeam-compatible) sans coût de licence. Choix aligné avec les contraintes budgétaires du projet pédagogique.

---

## 2. Firewall - FortiGate vs pfSense vs Palo Alto

| Critère | **FortiGate 60F HA** ✅ | pfSense CE | Palo Alto PA-220 |
|---|---|---|---|
| **Coût matériel** | ~1 800 € (×2 HA) | 0 € (soft) + ~500 € hardware | ~3 500 € |
| **Licence annuelle** | ~800 €/an (UTM) | 0 € (CE) | ~2 000 €/an |
| **TCO 3 ans** | ~6 000 € | **~500 €** | ~9 500 € |
| **VPN SSL + MFA natif** | ✅ FortiClient | ✅ (OpenVPN) | ✅ GlobalProtect |
| **Zero Trust NAC** | ✅ FortiNAC | ❌ | ✅ |
| **HA Active/Passive** | ✅ natif | ✅ (CARP) | ✅ |
| **NGFW (IPS/AV/App-Ctrl)** | ✅ complet | ⚠️ basique (Snort) | ✅ complet |
| **Interface d'admin** | Intuitive | Web standard | Complexe |
| **Certifications** | FIPS 140-2, CC EAL4+ | Aucune | FIPS 140-2, CC |

**Recommandation : FortiGate 60F HA**
Malgré un TCO supérieur à pfSense, le FortiGate est choisi pour son **Zero Trust NAC intégré**, son **MFA natif FortiClient**, et sa **certification CC EAL4+** - exigences justifiées par le contexte de plateforme de streaming avec authentification SSO. pfSense reste la solution de référence pour un budget très contraint sans besoins NAC avancés.

---

## 3. Stack Monitoring - Grafana/Prometheus/Loki vs ELK Stack vs Splunk

| Critère | **Grafana + Prometheus + Loki** ✅ | ELK Stack | Splunk Enterprise |
|---|---|---|---|
| **Licence** | **Gratuit (open-source)** | Gratuit (OSS) / ~5 000 €/an (Enterprise) | ~50 000 €/an (>10 GB/j) |
| **TCO 3 ans** | **0 €** | 0–15 000 € | ~150 000 € |
| **Métriques (time-series)** | ✅ Prometheus natif | ⚠️ Metricbeat (lourd) | ✅ |
| **Logs** | ✅ Loki (léger) | ✅ Elasticsearch | ✅ |
| **Dashboards** | ✅ Grafana | ✅ Kibana | ✅ |
| **RAM requise** | ~500 Mo | ~4 Go minimum | ~8 Go minimum |
| **Alerting** | ✅ Grafana Alerting | ✅ ElastAlert | ✅ |
| **Intégration Docker** | ✅ natif (Promtail) | ⚠️ complexe | ✅ |
| **Courbe apprentissage** | Faible | Moyenne | Faible (mais coûteux) |

**Recommandation : Grafana + Prometheus + Loki (stack PLG)**
**Économie vs Splunk : ~150 000 € sur 3 ans.** La stack PLG est la référence open-source pour le monitoring de containers. Loki est particulièrement adapté : il n'indexe que les métadonnées des logs (contrairement à Elasticsearch qui indexe tout), réduisant la consommation RAM de 80 % - avantage décisif sur un seul serveur physique.

---

## 4. IAM / SSO - Keycloak vs Okta vs Azure AD B2C

| Critère | **Keycloak** ✅ | Okta | Azure AD B2C |
|---|---|---|---|
| **Licence** | **Gratuit (open-source)** | ~4 €/utilisateur/mois | ~0,0016 $/authentification |
| **TCO 3 ans (100 users)** | **0 €** | ~14 400 € | ~300–2 000 € |
| **SSO (OIDC/SAML)** | ✅ | ✅ | ✅ |
| **MFA** | ✅ (TOTP, WebAuthn) | ✅ | ✅ |
| **Self-hosted** | ✅ | ❌ SaaS | ❌ SaaS |
| **LDAP / AD federation** | ✅ | ✅ | ✅ |
| **Admin UI** | ✅ | ✅ | ✅ |
| **Conformité RGPD (données en Europe)** | ✅ (on-premise) | ⚠️ (USA) | ⚠️ (USA) |

**Recommandation : Keycloak**
Keycloak est choisi pour son **hébergement on-premise** (conformité RGPD - données utilisateurs ne quittent pas le périmètre), sa **gratuité totale** et son support natif OIDC/SAML compatible Jellyfin et Traefik. Okta et Azure AD B2C introduisent une dépendance cloud et des coûts récurrents inadaptés au contexte.

---

## 5. Stockage Objet - MinIO vs AWS S3 vs Ceph

| Critère | **MinIO** ✅ | AWS S3 | Ceph |
|---|---|---|---|
| **Licence** | Gratuit (AGPLv3) | Pay-per-use | Gratuit (open-source) |
| **TCO 3 ans (1 To)** | **~0 €** (stockage local) | ~700 € | ~0 € + infra |
| **API S3-compatible** | ✅ 100% compatible | ✅ (natif) | ✅ (RadosGW) |
| **Self-hosted** | ✅ | ❌ Cloud | ✅ |
| **Setup complexity** | **Faible** (1 container) | Aucun (SaaS) | Très élevée (cluster min. 3 nœuds) |
| **Performance** | Haute (NVMe local) | Variable (réseau) | Haute (mais complexe) |
| **Portabilité** | ✅ | ❌ (vendor lock-in) | ✅ |

**Recommandation : MinIO**
MinIO déploie en **un seul container** une API S3 complète sur stockage local, sans vendor lock-in et sans coût. Ceph est plus puissant mais nécessite un cluster de 3 nœuds minimum - inadapté à notre architecture mono-serveur. AWS S3 introduit une dépendance cloud et un coût récurrent. MinIO permet également une **migration future transparente vers AWS S3** (même API).

---

## 6. Synthèse budgétaire - TCO comparatif sur 3 ans

| Composant | Solution retenue | TCO 3 ans | Alternative la moins chère | Différence |
|---|---|---|---|---|
| Hyperviseur | Proxmox VE | **0 €** | Hyper-V : 2 700 € | −2 700 € |
| Firewall | FortiGate HA | 6 000 € | pfSense : 500 € | +5 500 € (justifié NAC/MFA) |
| Monitoring | Grafana/Prometheus/Loki | **0 €** | ELK OSS : 0 € | = |
| IAM/SSO | Keycloak | **0 €** | Azure AD B2C : ~2 000 € | −2 000 € |
| Stockage objet | MinIO | **0 €** | AWS S3 (1To) : 700 € | −700 € |
| **TOTAL** | | **~6 000 €** | Scénario tout-cloud : ~166 000 € | **−160 000 €** |

**Le choix d'une stack open-source auto-hébergée permet une économie estimée à 160 000 € sur 3 ans** par rapport à un scénario tout-SaaS/cloud équivalent, tout en conservant la maîtrise des données et la conformité RGPD.
