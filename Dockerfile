FROM nlss/base-alpine:latest as mariadb-s6

LABEL maintainer="Aleksandar Puharic <xzero@elite7hackers.net>"

# S6 Supervisor config
ENV S6_KEEP_ENV=1
ENV S6_SYNC_DISKS=1
ENV S6_FIX_ATTRS_HIDDEN=1
ENV S6_SERVICES_GRACETIME=10000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KILL_FINISH_MAXTIME=15000
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=8000

WORKDIR /root

ENV CRON_ENABLED=true

RUN adduser --shell /bin/false --disabled-password --gecos "MariaDB User" --home "/var/lib/mysql" "mysql" \
    && apk add --update --upgrade --no-cache bash mariadb mariadb-client mariadb-server-utils tzdata \
    && rm -rf /etc/mysql/* /etc/my.cnf* /var/lib/mysql/*

# Install gomplate
COPY --from=hairyhenderson/gomplate:v3.7.0-alpine /bin/gomplate /usr/bin/gomplate

ADD rootfs /

VOLUME ["/var/lib/mysql", "/var/lib/backup"]
EXPOSE 3306
