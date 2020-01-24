FROM nlss/base-alpine:latest as mariadb-s6

LABEL maintainer="Aleksandar Puharic <xzero@elite7hackers.net>"

# S6 Supervisor config
ENV S6_KEEP_ENV=1
ENV S6_SYNC_DISKS=1
ENV S6_FIX_ATTRS_HIDDEN=1

WORKDIR /root

ENV CRON_ENABLED=true

RUN adduser --shell /bin/false --disabled-password --gecos "MariaDB User" --home "/var/lib/mysql" "mysql" \
    && apk add --update --upgrade --no-cache bash mariadb mariadb-client mariadb-server-utils tzdata \
    && rm -rf /etc/mysql/* /etc/my.cnf* /var/lib/mysql/*

# Install gomplate
COPY --from=hairyhenderson/gomplate:v3.6.0-slim /gomplate /usr/bin/gomplate

ADD rootfs /

VOLUME ["/var/lib/mysql", "/var/lib/backup"]
EXPOSE 3306
