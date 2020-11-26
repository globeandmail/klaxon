#!/bin/bash
set -e

if [[ "$RAILS_ENV" == "production" || "$RAILS_ENV" == "prod" ]]; then
  echo "Production environment detected. Clearing logs and tmp directory and precompiling assets…"
  # Clear logs
  DB_ADAPTER="nulldb" bundle exec rake log:clear

  # Remove contents of tmp dirs
  DB_ADAPTER="nulldb" bundle exec rake tmp:clear

  # Precompile assets
  DB_ADAPTER="nulldb" bundle exec rake assets:precompile
fi
