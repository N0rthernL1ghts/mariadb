FROM nlss/base-alpine:latest as mariadb-s6

LABEL maintainer="Aleksandar Puharic <xzero@elite7hackers.net>"

# S6 Supervisor config
ENV S6_KEEP_ENV=1
ENV S6_SYNC_DISKS=1
ENV S6_FIX_ATTRS_HIDDEN=1


EXPOSE 3306

VOLUME ["/var/lib/mysql", "/var/lib/backup"]
WORKDIR /root
ENTRYPOINT ["/usr/bin/entrypoint"]
CMD ["/bin/s6-svscan", "/etc/s6"]

ENV CRON_ENABLED=true

RUN apk add --update --upgrade --no-cache bash mariadb mariadb-client mariadb-server-utils tzdata \
    && groupadd -g 1000 mysql \
    && useradd -u 1000 -d /var/lib/mysql -g mysql -s /bin/bash -m mysql \
    && /etc/mysql/* /etc/my.cnf* /var/lib/mysql/*

ADD rootfs /
