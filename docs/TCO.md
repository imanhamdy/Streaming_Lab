# Comparatif TCO (Total Cost of Ownership)
## Streaming Lab — Ynov Campus B3 INFRA

**Version :** 1.0  
**Date :** Juillet 2026  
**Périmètre :** Infrastructure de streaming multimédia sur 3 ans  
**Note :** Le serveur Dell T140 est fourni par l'établissement — aucun CAPEX matériel.

---

## 1. Scénarios comparés

| | **A — On-premise** | **B — AWS** | **C — SaaS** |
|-|:------------------:|:-----------:|:------------:|
| Infrastructure | Dell T140 + Proxmox | EC2 + RDS + S3 | Plex + Auth0 + Datadog |
| Logiciels | 100 % open source | Managés AWS | Abonnements tiers |
| CAPEX | 0 € (matériel fourni) | 0 € | 0 € |
| **OPEX/an** | **~96 €** | **~2 400 €** | **~1 100 €** |
| **TCO 3 ans** | **~290 €** | **~7 200 €** | **~3 300 €** |

*OPEX on-premise : électricité ~84 €/an + domaine 12 €/an. AWS : EC2 t3.large + RDS + S3 + ALB. SaaS : licences Plex Pass, Auth0, Datadog, Backblaze.*

---

## 2. Comparatif multi-critères

| Critère | On-premise | AWS | SaaS |
|---------|:----------:|:---:|:----:|
| **Coût 3 ans** | ✅ ~290 € | ❌ ~7 200 € | ⚠️ ~3 300 € |
| **Compétences administration** | ✅ Système, réseau, Docker, sécurité | ⚠️ Cloud uniquement | ❌ Minimales |
| **Contrôle des données** | ✅ Total, hébergement local | ⚠️ Dépendance fournisseur US | ❌ Données chez des tiers |
| **Conformité RGPD** | ✅ Maîtrisée | ⚠️ Complexe (transferts hors UE) | ⚠️ Variable selon service |
| **Scalabilité** | ❌ Limitée au matériel | ✅ Illimitée | ✅ Illimitée |
| **Disponibilité (SLA)** | ⚠️ Pas de SLA formel | ✅ 99,9 % garanti | ✅ 99,9 %+ |
| **Déploiement initial** | ⚠️ Plusieurs semaines | ⚠️ Quelques jours | ✅ Immédiat |

---

## 3. Conclusion

La solution on-premise est **25× moins chère qu'AWS** sur 3 ans et **11× moins chère qu'une stack SaaS**, grâce à l'absence de CAPEX (matériel fourni) et à l'usage exclusif de logiciels open source.

Au-delà du coût, elle offre deux avantages stratégiques pour un projet B3 INFRA :

- **Compétences** : administration système Linux, virtualisation Proxmox, orchestration Docker, sécurité réseau (FortiGate, VLANs), gestion des identités (Keycloak), observabilité (Prometheus/Grafana/Loki) — compétences directement valorisables en entreprise.
- **Souveraineté des données** : hébergement local, aucune dépendance à un fournisseur cloud étranger, conformité RGPD simplifiée.

En contrepartie, l'architecture mono-nœud implique un point de défaillance unique (SPoF). En production réelle, une approche hybride (on-premise pour les données sensibles + cloud pour l'élasticité) serait à envisager.
