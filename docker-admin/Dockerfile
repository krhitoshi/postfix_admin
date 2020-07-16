FROM postfixadmin:3.2.4-apache

RUN apt-get update && \
    apt-get install -y dovecot-core iproute2 mariadb-client && \
    rm -rf /var/lib/apt/lists/*

