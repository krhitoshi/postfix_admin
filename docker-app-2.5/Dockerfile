FROM ruby:2.5.0

RUN apt-get update && \
    apt-get install -y dovecot-core iproute2 mariadb-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile postfix_admin.gemspec ./
COPY ./lib/postfix_admin/version.rb ./lib/postfix_admin/version.rb

RUN gem install bundler && bundle install

COPY spec/postfix_admin.conf /root/.postfix_admin.conf
COPY docker-app/my.cnf /root/.my.cnf
