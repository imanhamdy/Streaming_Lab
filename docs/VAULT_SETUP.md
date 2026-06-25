# HashiCorp Vault - Configuration et initialisation

URL : http://192.168.10.2:8200  
Config : `docker/security/vault-config.hcl`

---

## 1. Initialisation (une seule fois)

```bash
docker exec vault vault operator init
```

Vault génère **5 Unseal Keys** et **1 Root Token** :

```
Unseal Key 1: <key1>
Unseal Key 2: <key2>
Unseal Key 3: <key3>
Unseal Key 4: <key4>
Unseal Key 5: <key5>

Initial Root Token: hvs.XXXXXXXXXXXX
```

**IMPORTANT** : Sauvegarde ces valeurs en lieu sûr - elles ne s'affichent qu'une seule fois. Ne les commite jamais dans git.

---

## 2. Unseal (à chaque redémarrage)

Vault démarre toujours verrouillé (sealed). Il faut fournir 3 des 5 unseal keys pour le déverrouiller :

```bash
docker exec -it vault vault operator unseal <key1>
docker exec -it vault vault operator unseal <key2>
docker exec -it vault vault operator unseal <key3>
```

Vérifier le statut :
```bash
docker exec vault vault status
```

Résultat attendu : `Sealed: false`

---

## 3. Authentification

```bash
export VAULT_ADDR=http://192.168.10.2:8200
export VAULT_TOKEN=<root_token>
```

Ou via l'UI : http://192.168.10.2:8200 → **Token** → coller le Root Token

---

## 4. Créer les secrets

### Activer le moteur KV
```bash
docker exec vault vault secrets enable -path=secret kv-v2
```

### Stocker les secrets de la stack
```bash
# Databases
docker exec vault vault kv put secret/databases \
  postgres_user=streaminglab \
  postgres_password=<valeur> \
  postgres_db=keycloak \
  mongo_user=streaminglab \
  mongo_password=<valeur> \
  redis_password=<valeur>

# Keycloak
docker exec vault vault kv put secret/keycloak \
  admin_user=admin \
  admin_password=<valeur>

# Grafana
docker exec vault vault kv put secret/grafana \
  admin_user=principal \
  admin_password=<valeur> \
  keycloak_client_secret=<valeur>

# MinIO
docker exec vault vault kv put secret/minio \
  root_user=streaminglab \
  root_password=<valeur> \
  keycloak_client_secret=<valeur>
```

### Lire un secret
```bash
docker exec vault vault kv get secret/databases
```

---

## 5. Créer une politique d'accès

```bash
docker exec vault vault policy write streaming-lab - <<EOF
path "secret/data/*" {
  capabilities = ["read"]
}
EOF
```

---

## 6. Créer un token pour les applications

```bash
docker exec vault vault token create \
  -policy=streaming-lab \
  -ttl=8760h \
  -display-name=streaming-lab-apps
```

---

## 7. Unseal automatique (optionnel)

Pour éviter de devoir unseal manuellement à chaque redémarrage, créer un script :

```bash
cat > ~/streaming-lab/scripts/unseal-vault.sh << 'EOF'
#!/bin/bash
docker exec vault vault operator unseal <key1>
docker exec vault vault operator unseal <key2>
docker exec vault vault operator unseal <key3>
EOF
chmod +x ~/streaming-lab/scripts/unseal-vault.sh
```

Ajouter en crontab après reboot :
```bash
@reboot sleep 30 && /home/principal/streaming-lab/scripts/unseal-vault.sh
```

---

## 8. Connexion des applications à Vault

Les apps lisent leurs secrets depuis Vault au lieu du `.env`. Deux approches :

### Option A - Via variable d'environnement (simple)

Ajouter dans chaque compose le token applicatif et l'adresse Vault, puis utiliser un entrypoint qui lit les secrets au démarrage.

Exemple pour Grafana dans `docker/monitoring/docker-compose.yml` :
```yaml
environment:
  - VAULT_ADDR=http://192.168.10.2:8200
  - VAULT_TOKEN=<app_token>
```

Puis dans un script d'init :
```bash
GF_SECURITY_ADMIN_PASSWORD=$(vault kv get -field=admin_password secret/grafana)
```

### Option B - Via Vault Agent (recommandé)

Vault Agent tourne en sidecar et écrit les secrets dans des fichiers que l'app lit.

**1. Créer la config Vault Agent**

```hcl
# docker/security/vault-agent.hcl
vault {
  address = "http://192.168.10.2:8200"
}

auto_auth {
  method "token_file" {
    config = {
      token_file_path = "/vault/token"
    }
  }
}

template {
  source      = "/vault/templates/grafana.env.tpl"
  destination = "/vault/secrets/grafana.env"
}
```

**2. Template pour Grafana**

```
{{- with secret "secret/data/grafana" -}}
GF_SECURITY_ADMIN_USER={{ .Data.data.admin_user }}
GF_SECURITY_ADMIN_PASSWORD={{ .Data.data.admin_password }}
{{- end }}
```

**3. Charger le fichier généré dans le compose**

```yaml
env_file:
  - /vault/secrets/grafana.env
```

### Lire un secret manuellement depuis la VM

```bash
# Avec le token root
docker exec vault vault kv get -field=admin_password secret/grafana

# Avec le token applicatif
VAULT_TOKEN=<app_token> docker exec vault vault kv get secret/grafana
```

---

## 9. Vérification

```bash
docker exec vault vault status
docker exec vault vault kv list secret/
```

| Champ | Valeur attendue |
|-------|-----------------|
| Initialized | true |
| Sealed | false |
| Storage type | file |
| HA Enabled | false |
