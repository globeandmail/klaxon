#!/bin/bash
set -e

# If it exists, remove a potentially pre-existing server.pid for Rails.
if [ -f /klaxon/tmp/pids/server.pid ]; then
  rm /klaxon/tmp/pids/server.pid
fi

echo "Checking if database exists…"

DB_NAME=$PGDBNAME

if [[ "$RAILS_ENV" != "production" && "$RAILS_ENV" != "prod" ]]; then
  DB_NAME="${DB_NAME}-${RAILS_ENV}"
fi

# run get_secrets.rb to create a temp env var file, then set 'em, then delete it
/usr/bin/set_secrets.rb
eval $(cat /tmp/secrets.env | sed 's/^/export /')
rm -f /tmp/secrets.env

# then pass vars to psql
if echo "\c $DB_NAME; \dt" | psql -h "$PGHOST" -U "$PGUSER" -d "$DB_NAME" | grep schema_migrations 2>&1 >/dev/null
then
  echo "Past migrations found. Running any new migrations…"
  bundle exec rake db:migrate
else
  echo "Database does not exist. Creating database, schema and seeding…"
  bundle exec rake db:setup
  if [ ! -z "$ADMIN_EMAILS" ]; then
    echo "Admin emails detected. Creating admin accounts…"
    bundle exec rake users:create_admin
  fi
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
