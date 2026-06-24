# Keycloak — Configuration SSO

URL : http://192.168.10.2:8081  
Admin : `admin` / `K3ycl0ak#Admin2026!`

---

## 1. Créer le Realm

1. Se connecter à l'interface admin
2. Menu haut gauche → **Create Realm**
3. Nom : `streaming-lab`
4. **Enabled** : ON → **Create**

---

## 2. Créer les Rôles

Dans le realm `streaming-lab` → **Realm roles** → **Create role**

| Rôle | Description |
|------|-------------|
| `admin` | Accès complet à tous les services |
| `viewer` | Accès lecture seule (Grafana, Jellyfin) |
| `media-user` | Accès Jellyfin uniquement |

---

## 3. Créer les Utilisateurs

**Realm roles** → **Users** → **Create user**

### Admin principal
| Champ | Valeur |
|-------|--------|
| Username | `principal` |
| Email | `hamdy.iman2003@gmail.com` |
| First name | `Principal` |
| Email verified | ON |

Onglet **Credentials** → **Set password** → définir un mot de passe → **Temporary** : OFF

Onglet **Role mapping** → **Assign role** → `admin`

---

## 4. Créer les Clients (une app par service)

### 4.1 Grafana

**Clients** → **Create client**

| Champ | Valeur |
|-------|--------|
| Client type | `OpenID Connect` |
| Client ID | `grafana` |
| Name | `Grafana` |

Page suivante :
| Champ | Valeur |
|-------|--------|
| Client authentication | ON |
| Authorization | OFF |
| Standard flow | ON |

Page suivante :
| Champ | Valeur |
|-------|--------|
| Root URL | `http://192.168.10.2:3000` |
| Valid redirect URIs | `http://192.168.10.2:3000/*` |
| Web origins | `http://192.168.10.2:3000` |

→ **Save** → onglet **Credentials** → copier le `Client secret`

Ajouter dans `docker/.env` :
```
KEYCLOAK_CLIENT_SECRET_GRAFANA=<secret>
```

Ajouter dans `docker/monitoring/docker-compose.yml` sous grafana environment :
```yaml
- GF_AUTH_GENERIC_OAUTH_ENABLED=true
- GF_AUTH_GENERIC_OAUTH_NAME=Keycloak
- GF_AUTH_GENERIC_OAUTH_CLIENT_ID=grafana
- GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET_GRAFANA}
- GF_AUTH_GENERIC_OAUTH_SCOPES=openid email profile
- GF_AUTH_GENERIC_OAUTH_AUTH_URL=http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/auth
- GF_AUTH_GENERIC_OAUTH_TOKEN_URL=http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/token
- GF_AUTH_GENERIC_OAUTH_API_URL=http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/userinfo
- GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH=contains(roles[*], 'admin') && 'Admin' || 'Viewer'
```

### 4.2 MinIO

**Clients** → **Create client**

| Champ | Valeur |
|-------|--------|
| Client type | `OpenID Connect` |
| Client ID | `minio` |

Page suivante :
| Champ | Valeur |
|-------|--------|
| Client authentication | ON |
| Standard flow | ON |

| Champ | Valeur |
|-------|--------|
| Root URL | `http://192.168.10.2:9001` |
| Valid redirect URIs | `http://192.168.10.2:9001/*` |

→ **Save** → onglet **Credentials** → copier le `Client secret`

Dans la console MinIO (http://192.168.10.2:9001) :
- **Identity** → **OpenID** → **Add**

| Champ | Valeur |
|-------|--------|
| Config URL | `http://192.168.10.2:8081/realms/streaming-lab/.well-known/openid-configuration` |
| Client ID | `minio` |
| Client Secret | `<secret>` |
| Claim Name | `roles` |
| Display Name | `Keycloak` |

### 4.3 Jellyfin

Jellyfin ne supporte pas nativement OpenID Connect sans plugin. Installer le plugin **SSO-Auth** :

1. Jellyfin → **Dashboard** → **Plugins** → **Catalogue**
2. Chercher `SSO Authentication` → **Install**
3. Redémarrer Jellyfin
4. **Dashboard** → **Plugins** → **SSO-Auth** → **Settings**

| Champ | Valeur |
|-------|--------|
| Provider name | `Keycloak` |
| OID Endpoint | `http://192.168.10.2:8081/realms/streaming-lab` |
| Client ID | `jellyfin` |
| Client Secret | `<secret>` |

Créer le client `jellyfin` dans Keycloak avec redirect URI : `http://192.168.10.2:8096/*`

---

## 5. Vérification

Tester l'endpoint de découverte Keycloak :
```bash
curl http://192.168.10.2:8081/realms/streaming-lab/.well-known/openid-configuration
```

Doit retourner un JSON avec les URLs d'auth, token, userinfo.

---

## 6. Résumé des URLs Keycloak

| Endpoint | URL |
|----------|-----|
| Auth | `http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/auth` |
| Token | `http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/token` |
| Userinfo | `http://192.168.10.2:8081/realms/streaming-lab/protocol/openid-connect/userinfo` |
| Discovery | `http://192.168.10.2:8081/realms/streaming-lab/.well-known/openid-configuration` |
