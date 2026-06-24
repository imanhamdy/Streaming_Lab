# RFC-001 — Déploiement stack MinIO (Storage-net)
**Request For Change — Streaming Lab**
Date de soumission : 23 juin 2026 | Statut : **CLÔTURÉ ✅**

---

## 1. Identification

| Champ | Valeur |
|---|---|
| **RFC ID** | RFC-001 |
| **Type de changement** | Normal |
| **Priorité** | Moyenne |
| **Change Initiator** | Iman Hamdy |
| **Change Manager** | Iman Hamdy |
| **Date de soumission** | 23 juin 2026 |
| **Fenêtre d'implémentation** | 23 juin 2026 — hors heures de production |
| **Branche Git** | `feature/bases-de-donnees` |

---

## 2. Description du changement

### 2.1 Résumé
Déploiement d'un service de stockage objet **MinIO** (compatible S3) sur le réseau Docker `storage-net` de `vm-streaming`, afin de centraliser le stockage des médias (fichiers Jellyfin) et de fournir un point d'accès S3 aux autres services applicatifs.

### 2.2 Justification
- Jellyfin nécessite un stockage structuré et scalable pour les fichiers média
- MinIO fournit une API S3 compatible, permettant une migration future vers AWS S3 sans changement applicatif
- La séparation sur un réseau dédié (`storage-net`) renforce l'isolation de sécurité

### 2.3 Composants modifiés

| Fichier | Nature de la modification |
|---|---|
| `docker/storage/docker-compose.yml` | Nouveau fichier — définition service MinIO |
| `docker/.env` | Ajout variables `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` |
| `docker/.env.example` | Ajout entrées MinIO pour la documentation |

---

## 3. Analyse des risques

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Échec démarrage container MinIO | Faible | Moyen | Image officielle stable ; volumes nommés préservent les données |
| Conflit de port (9000/9001) | Faible | Faible | Ports non utilisés par d'autres services |
| Credentials exposés | Très faible | Élevé | Variables dans `docker/.env` exclu du dépôt Git |
| Rupture réseau `storage-net` | Très faible | Moyen | Réseau créé préalablement (KAN-33 — Done) |

**Niveau de risque global : FAIBLE**

---

## 4. Plan de rollback

En cas d'échec lors de l'implémentation :

```bash
# 1. Arrêter le service MinIO
docker compose -f docker/storage/docker-compose.yml down

# 2. Supprimer le volume si corrompu
docker volume rm storage_minio_data

# 3. Revenir au commit précédent
git revert HEAD
git push origin feature/bases-de-donnees
```

Impact du rollback : aucun autre service n'est affecté (storage-net isolé).

---

## 5. Plan d'implémentation

| Étape | Action | Responsable | Durée estimée |
|---|---|---|---|
| 1 | Rédiger `docker/storage/docker-compose.yml` | Iman H. | 15 min |
| 2 | Ajouter credentials MinIO dans `docker/.env` | Iman H. | 5 min |
| 3 | Mettre à jour `docker/.env.example` | Iman H. | 5 min |
| 4 | Review PR par un membre de l'équipe | Équipe | 10 min |
| 5 | Merge dans `feature/bases-de-donnees` | Iman H. | 2 min |
| 6 | Test de démarrage sur vm-streaming | Iman H. | 10 min |
| **Total** | | | **~47 min** |

---

## 6. Tests de validation

Après déploiement, vérifier :

```bash
# Vérifier que MinIO est UP
docker ps | grep minio
# Attendu : container "minio" en status "Up"

# Vérifier la santé
docker exec minio mc ready local
# Attendu : "The cluster is ready"

# Vérifier l'accès console web (depuis VPN)
curl -I http://192.168.50.10:9001
# Attendu : HTTP 200
```

---

## 7. Approbation CAB

| Membre | Rôle | Décision | Date |
|---|---|---|---|
| Iman Hamdy | Change Manager | ✅ Approuvé | 23/06/2026 |
| Quentin | Admin réseau | ✅ Approuvé | 23/06/2026 |
| Adrien | Admin monitoring | ✅ Approuvé | 23/06/2026 |

---

## 8. Clôture

| Champ | Valeur |
|---|---|
| **Date d'implémentation** | 23 juin 2026 |
| **Résultat** | Succès ✅ |
| **Commit Git** | `2d03c10` sur `feature/bases-de-donnees` |
| **Anomalies constatées** | Aucune |
| **Actions post-implémentation** | Ajouter scrape MinIO dans Prometheus (RFC-004) |
