# syntax=docker/dockerfile:1
# Modal hosts the Rails process; PostgreSQL is available ONLY for disposable demo mode.
ARG RUBY_VERSION=3.4.11
FROM ruby:${RUBY_VERSION}-slim
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_LOG_TO_STDOUT=true
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
    ca-certificates curl libpq5 libpq-dev postgresql postgresql-client \
    redis-server build-essential git libyaml-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /rails
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf /root/.bundle /usr/local/bundle/ruby/*/cache
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 SKIP_PRODUCTION_BOOT_CHECKS=true \
    DATABASE_URL=postgresql://unused:unused@localhost/unused \
    bin/rails assets:precompile
EXPOSE 3000
