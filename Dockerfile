FROM nlss/attr AS attr
FROM nlss/s6-rootfs:2.2 AS s6-overlay
FROM hairyhenderson/gomplate:v3.11.5-alpine AS gomplate


# Build rootfs
FROM scratch AS rootfs

# Install s6 supervisor
COPY --from=s6-overlay ["/", "/"]

# Install utils
COPY --from=gomplate  ["/bin/gomplate", "/usr/bin/gomplate"]
COPY --from=attr      ["/usr/local/bin/attr", "/usr/local/bin/"]

# Copy overlay
COPY ["rootfs", "/"]


# Final stage
FROM alpine:3.18

RUN adduser --shell /bin/false --disabled-password --gecos "MariaDB User" --home "/var/lib/mysql" "mysql" \
    && apk add --update --upgrade --no-cache bash mariadb mariadb-client mariadb-server-utils tzdata \
    && rm -rf /etc/mysql/* /etc/my.cnf* /var/lib/mysql/*

COPY --from=rootfs ["/", "/"]

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>"

# S6 Supervisor config
ENV S6_KEEP_ENV=1
ENV S6_SYNC_DISKS=1
ENV S6_FIX_ATTRS_HIDDEN=1
ENV S6_SERVICES_GRACETIME=10000
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_KILL_FINISH_MAXTIME=15000
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=8000

WORKDIR "/root"
VOLUME ["/var/lib/mysql"]
ENTRYPOINT ["/init"]

# Expose primary port, and also administrative port
EXPOSE 3306/TCP
EXPOSE 8385/TCP