FROM centos:8

RUN dnf -y module enable ruby:2.6 \
    && dnf -y install \
    ruby ruby-devel mariadb-devel sqlite-devel gcc make redhat-rpm-config \
    mariadb dovecot git \
    && dnf clean all

WORKDIR /app

COPY Gemfile postfix_admin.gemspec ./
COPY ./lib/postfix_admin/version.rb ./lib/postfix_admin/version.rb

RUN gem install bundler && bundle install

COPY spec/postfix_admin.conf /root/.postfix_admin.conf

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 80

CMD ["/sbin/init"]