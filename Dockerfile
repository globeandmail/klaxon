FROM ruby:2.5.7

# Installation of dependencies, specifically psql
RUN apt-get update -qq \
  && apt-get install -y \
    # Needed for certain gems
    build-essential \
    # # Needed for postgres gem
    libpq-dev \
    lsb-release \
    curl && \
    curl -sS https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | tee  /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && apt-get install -y \
    postgresql-client-9.6 \
    # The following are used to trim down the size of the image by removing unneeded data
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf \
      /var/lib/apt \
      /var/lib/dpkg \
      /var/lib/cache \
      /var/lib/log

# Setup environment variables that will be available to the instance
ENV APP_HOME /klaxon

RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile $APP_HOME/
COPY Gemfile.lock $APP_HOME/

# throw errors if Gemfile has been modified since Gemfile.lock
RUN gem update bundler
RUN bundle config --global frozen 1

RUN bundle install --jobs 5

ADD . $APP_HOME

# Clearing logs
# RUN bin/rake log:clear

# Removing contents of tmp dirs
# RUN bin/rake tmp:clear

# Precompile assets
# RUN bin/rake assets:precompile

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

COPY set_secrets.rb /usr/bin/
RUN chmod +x /usr/bin/set_secrets.rb

ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# Run our app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
