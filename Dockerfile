FROM golang:alpine AS mars-builder

WORKDIR "/tmp/mars"

RUN apk add --no-cache git \
    && GOPATH=/tmp/mars \
       go get github.com/xZero707/mysql-backup-golang


##########
# Main
FROM nlss/base-alpine:3.12 AS mariadb-s6

LABEL maintainer="Aleksandar Puharic <xzero@elite7hackers.net>"

# S6 Supervisor config
ENV S6_KEEP_ENV=1
ENV S6_SYNC_DISKS=1
ENV S6_FIX_ATTRS_HIDDEN=1
ENV S6_SERVICES_GRACETIME=10000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KILL_FINISH_MAXTIME=15000
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=8000

# Backup configuration
ENV BACKUP_BATCH_SIZE=1000000
ENV BACKUP_TABLE_THRESHOLD=5000000
ENV BACKUP_RETENTION_DAYS=5
ENV BACKUP_RETENTION_WEEKS=2
ENV BACKUP_RETENTION_MONTHS=1
ENV BACKUP_CRON_VERBOSE=false

WORKDIR /root

ENV CRON_ENABLED=true

RUN adduser --shell /bin/false --disabled-password --gecos "MariaDB User" --home "/var/lib/mysql" "mysql" \
    && wget -O /usr/local/bin/attr https://gist.githubusercontent.com/xZero707/7a3fb3e12e7192c96dbc60d45b3dc91d/raw/44a755181d2677a7dd1c353af0efcc7150f15240/attr.sh \
    && chmod a+x /usr/local/bin/attr \
    && apk add --update --upgrade --no-cache bash mariadb mariadb-client mariadb-server-utils tzdata \
    && rm -rf /etc/mysql/* /etc/my.cnf* /var/lib/mysql/*

# Install utils
COPY --from=hairyhenderson/gomplate:v3.9.0-alpine /bin/gomplate  /usr/bin/gomplate
COPY --from=mars-builder /tmp/mars/bin/mysql-backup-golang /usr/bin/mars

ADD rootfs /

VOLUME ["/var/lib/mysql", "/var/lib/backup"]
EXPOSE 3306
