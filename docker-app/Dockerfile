FROM ruby:3.1

RUN apt-get update && \
    apt-get install -y dovecot-core iproute2 mariadb-client && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile postfix_admin.gemspec ./
COPY ./lib/postfix_admin/version.rb ./lib/postfix_admin/version.rb

RUN gem install bundler && bundle install

COPY spec/postfix_admin.conf /root/.postfix_admin.conf
COPY docker-app/my.cnf /root/.my.cnf

# for GitHub Actions
RUN curl https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh -so /wait-for-it.sh && \
    chmod 755 /wait-for-it.sh

CMD ["irb"]
