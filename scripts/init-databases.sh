#!/bin/bash
set -e

echo "==> Testing database connections..."

# PostgreSQL
echo ""
echo "--- PostgreSQL ---"
PGPASS=$(docker exec vault vault kv get -field=postgres_password secret/databases)
PGUSER=$(docker exec vault vault kv get -field=postgres_user secret/databases)
PGDB=$(docker exec vault vault kv get -field=postgres_db secret/databases)

docker exec postgres psql -U "$PGUSER" -d "$PGDB" -c "\l" && echo "PostgreSQL OK"

# Create additional databases if needed
docker exec postgres psql -U "$PGUSER" -c "
  SELECT datname FROM pg_database WHERE datname NOT IN ('postgres','template0','template1');
" | grep -q "$PGDB" && echo "Database '$PGDB' exists"

# MongoDB
echo ""
echo "--- MongoDB ---"
MONGO_USER=$(docker exec vault vault kv get -field=mongo_user secret/databases)
MONGO_PASS=$(docker exec vault vault kv get -field=mongo_password secret/databases)

docker exec mongodb mongosh \
  --username "$MONGO_USER" \
  --password "$MONGO_PASS" \
  --authenticationDatabase admin \
  --eval "db.adminCommand({ listDatabases: 1 }).databases.map(d => d.name)" \
  --quiet && echo "MongoDB OK"

# Redis
echo ""
echo "--- Redis ---"
REDIS_PASS=$(docker exec vault vault kv get -field=redis_password secret/databases)

docker exec redis redis-cli -a "$REDIS_PASS" ping | grep -q "PONG" && echo "Redis OK"

echo ""
echo "==> All database connections OK"
