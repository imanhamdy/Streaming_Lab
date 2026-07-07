# Green IT & Éco-responsabilité - Streaming Lab
**Ynov Campus B3 INFRA
Version 1.0 - Juin 2026

---

## 1. Contexte et démarche

Le projet Streaming Lab intègre dès sa conception les principes du **Green IT** en cherchant à minimiser l'empreinte carbone du SI tout en garantissant les niveaux de service attendus. Chaque choix technique a été évalué sous deux angles : performance opérationnelle et impact environnemental.

---

## 2. Choix techniques éco-responsables 

### 2.1 Consolidation serveur - principal levier d'économie

L'architecture retenue concentre **l'intégralité de l'infrastructure** sur un seul serveur physique DELL T140 via Proxmox VE 8, au lieu de déployer plusieurs serveurs physiques dédiés.

| Scénario | Serveurs physiques | Conso. estimée | Émissions CO₂/an (0,06 kg/kWh) |
|---|---|---|---|
| Sans virtualisation | 3 serveurs × 120W | 3 153 kWh/an | **189 kg CO₂** |
| Avec Proxmox (réel) | 1 serveur × 65W (charge moy.) | 569 kWh/an | **34 kg CO₂** |
| **Économie réalisée** | **−2 serveurs** | **−2 584 kWh/an** | **−155 kg CO₂/an** |

> Hypothèse : facteur d'émission réseau électrique français = 0,06 kg CO₂/kWh (RTE 2024).

### 2.2 Conteneurisation Docker - densification des ressources

Les stacks Docker permettent de faire tourner **13 services** sur une seule VM (`vm-streaming`) avec un overhead minimal, là où 13 VMs dédiées auraient multiplié la consommation mémoire et CPU par 3 à 5.

| Approche | RAM utilisée (estimé) | CPU idle |
|---|---|---|
| 13 VMs dédiées | ~26 Go RAM | ~30% CPU |
| 13 containers Docker | ~6 Go RAM | ~8% CPU |
| **Gain** | **−20 Go RAM** | **−22% CPU** |

Moins de RAM active = moins de cycles mémoire = consommation réduite.

### 2.3 Images Docker légères (Alpine Linux)

Les images sélectionnées privilégient les variantes **Alpine** :

| Service | Image choisie | Taille | Alternative standard |
|---|---|---|---|
| PostgreSQL | `postgres:15-alpine` | ~80 Mo | `postgres:15` (~380 Mo) |
| Redis | `redis:7-alpine` | ~30 Mo | `redis:7` (~130 Mo) |
| Loki | `grafana/loki:latest` | ~65 Mo | - |

Images plus légères = moins de transferts réseau, moins de stockage, démarrages plus rapides.

### 2.4 Politique de rétention des logs optimisée

La configuration Loki applique une rétention de **168 heures (7 jours)** avec rejet des logs obsolètes :

```yaml
limits_config:
  reject_old_samples: true
  reject_old_samples_max_age: 168h
```

Cela évite l'accumulation illimitée de logs qui consommerait du stockage et de l'énergie inutilement, tout en conservant une fenêtre suffisante pour l'analyse de sécurité (BC03).

### 2.5 Politique de restart ciblée

Tous les containers utilisent `restart: unless-stopped` plutôt que `restart: always`. Cela permet l'arrêt propre des services lors des maintenances planifiées sans redémarrage automatique intempestif, économisant des cycles CPU pendant les fenêtres de maintenance.

### 2.6 Hébergement local - zéro transfert longue distance

L'infrastructure est hébergée **on-premise** dans les locaux d'Ynov Campus. Contrairement à une solution cloud distante, les flux de données entre utilisateurs et services ne transitent pas par des datacenters distants, réduisant la consommation réseau et la latence.

Le tunnel Cloudflare Zero Trust (KAN-25) est limité aux seuls accès externes entrants, le trafic interne restant local.

### 2.7 Sauvegarde incrémentale

Veeam B&R est configuré en mode **incrémental quotidien** avec une sauvegarde complète hebdomadaire uniquement. Les sauvegardes incrémentielles ne transfèrent que les blocs modifiés, réduisant la consommation réseau et d'espace disque de 80 à 95 % par rapport à des sauvegardes complètes quotidiennes.

---

## 3. Indicateurs environnementaux suivis 

Les KPIs suivants sont définis, mesurés via Prometheus/Grafana et révisés mensuellement :

### 3.1 KPIs d'efficacité énergétique

| Indicateur | Unité | Source | Seuil d'alerte | Objectif |
|---|---|---|---|---|
| Consommation CPU vm-streaming | % | Prometheus node-exporter | > 80% | < 60% (optimiser avant de scaler) |
| Utilisation RAM vm-streaming | % | Prometheus node-exporter | > 85% | < 70% |
| Taux de virtualisation | VMs / serveur physique | Manuel | < 2 | ≥ 3 |
| Charge CPU idle (nuit) | % | Prometheus | > 20% | < 10% |

### 3.2 KPIs de stockage et rétention

| Indicateur | Unité | Source | Seuil d'alerte | Objectif |
|---|---|---|---|---|
| Volume logs Loki | Go | Loki metrics | > 5 Go | < 3 Go (rétention 7j respectée) |
| Espace disque MinIO utilisé | % | Prometheus | > 80% | < 70% |
| Taux de déduplication Veeam | % | Veeam B&R | < 50% | > 70% |
| Taille sauvegarde incrémentale | Go | Veeam B&R | > 20 Go/j | < 5 Go/j |

### 3.3 KPIs de cycle de vie des équipements

| Indicateur | Valeur actuelle | Objectif RSE |
|---|---|---|
| Nombre de serveurs physiques | 1 (DELL T140) | Minimiser |
| Taux de virtualisation | 3 VMs / 1 serveur | ≥ 3 |
| Âge moyen des équipements | < 3 ans | Maximiser durée de vie (≥ 5 ans) |
| Équipements réutilisés | Cisco C3650 (reconditionné) | Favoriser reconditionné |

### 3.4 Calcul d'empreinte carbone mensuelle estimée

| Composant | Conso. mensuelle | Émissions CO₂ |
|---|---|---|
| DELL T140 (65W moy.) | 47 kWh | 2,8 kg CO₂ |
| Cisco C3650 (45W moy.) | 32 kWh | 1,9 kg CO₂ |
| FortiGate HA (2×30W) | 43 kWh | 2,6 kg CO₂ |
| **Total infrastructure** | **122 kWh/mois** | **7,3 kg CO₂/mois** |
| **Équivalent sans virtualisation** | ~315 kWh/mois | ~18,9 kg CO₂/mois |
| **Économie mensuelle** | **−193 kWh** | **−11,6 kg CO₂** |

---

## 4. Actions correctives et plan d'amélioration

| Action | Impact attendu | Statut |
|---|---|---|
| Configurer l'extinction automatique des stacks de test hors heures ouvrées | −10% consommation CPU | Planifié (KAN-20 DevOps) |
| Ajouter Prometheus node-exporter pour mesure CPU/RAM réelle | Mesures précises | En cours (KAN-19) |
| Activer la compression Loki (snappy) pour réduire stockage logs | −40% volume logs | Planifié |
| Migrer les images restantes vers Alpine si disponible | −200 Mo stockage image | Planifié |
| Mettre en place des alertes Grafana sur seuils de consommation | Réactivité proactive | En cours (KAN-19) |

---

## 5. Conclusion

Le Streaming Lab démontre qu'une infrastructure performante et éco-responsable sont compatibles. La consolidation sur un seul serveur physique permet d'éviter **155 kg de CO₂ par an** par rapport à une architecture non virtualisée équivalente. Les choix techniques (Alpine, rétention logs, sauvegardes incrémentielles, hébergement local) renforcent cette démarche à chaque niveau de la stack.

Ces indicateurs sont intégrés au tableau de bord Grafana pour un suivi continu et constituent des preuves mesurables de la démarche RSE du projet.

---

*Références : RTE - Bilan électrique 2024 ; ADEME - Empreinte carbone du numérique 2023 ; Green IT - Guide de bonnes pratiques v4.*
