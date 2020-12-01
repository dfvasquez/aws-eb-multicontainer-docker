ARG RUBY_VERSION
# All images must have a FROM
FROM ruby:$RUBY_VERSION


ENV BUNDLER_VERSION=2.0.2
ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG YARN_VERSION
ARG RAILS_MASTER_KEY

# Run all the following
RUN apt-get update \
    && apt-get install -y build-essential postgresql-client \
    && curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g yarn@$YARN_VERSION \
    && mkdir /app

# Configure bundler
ENV LANG=C.UTF-8 \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3

# Move to /app dir
WORKDIR /app

# Copy in [] what is in []
COPY . .

# Run all the following
RUN gem install bundler -v ${BUNDLER_VERSION} &&  gem update --system && bundler

# Run all the following
RUN yarn install --check-files

# Assets precompile onlu production
RUN rake assets:precompile RAILS_ENV=production RAILS_MASTER_KEY=${RAILS_MASTER_KEY}

EXPOSE 5000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"] 