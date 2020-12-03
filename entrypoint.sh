#!/bin/bash
set -e

if [[ ! -z "$AWS_REGION" && ! -z "$AWS_SECRETS_PREFIX" && -z "$DISABLE_AWS_SECRETS" ]]; then
  # Specific code for AWS secrets manager, if being used. Runs get_secrets.rb
  # to create a temp env var file, then sets envs, then deletes file.
  /usr/bin/set_secrets.rb
  eval $(cat /tmp/secrets.env | sed 's/^/export /')
  rm -f /tmp/secrets.env
fi

# If it exists, remove a potentially pre-existing server.pid for Rails.
if [ -f "$APP_HOME/tmp/pids/server.pid" ]; then
  rm "$APP_HOME/tmp/pids/server.pid"
fi

echo "Checking if database exists…"

CURR_DB_NAME=$DB_NAME

if [[ "$RAILS_ENV" != "production" && "$RAILS_ENV" != "prod" ]]; then
  CURR_DB_NAME="${DB_NAME}-${RAILS_ENV}"
fi

# Then pass vars to psql, which will test whether the DB exists.
# Need to explicitly declare a PGPASSWORD variable for psql, since
# it expects it in that format (instead of our DB_PASSWORD).
if echo "\c $CURR_DB_NAME; \dt" | PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USERNAME" -d "$CURR_DB_NAME" | grep schema_migrations 2>&1 >/dev/null
then
  echo "Database exists, past migrations found. Running any new migrations…"
  bundle exec rake db:migrate
else
  echo "Database does not exist. Creating database, schema and seeding…"
  bundle exec rake db:setup
  if [ ! -z "$ADMIN_EMAILS" ]; then
    echo "Admin emails detected. Creating admin accounts…"
    bundle exec rake users:create_admin
  fi
fi

# Finally, exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
