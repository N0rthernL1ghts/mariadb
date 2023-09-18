ARG BASE_ALPINE_VERSION="3.18"

FROM nlss/attr AS attr
FROM ghcr.io/n0rthernl1ghts/s6-rootfs:3.1 AS s6-overlay
FROM ghcr.io/hairyhenderson/gomplate:v3.11.5-alpine AS gomplate


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
ARG BASE_ALPINE_VERSION
FROM --platform=${TARGETPLATFORM} alpine:${BASE_ALPINE_VERSION}

ARG MARIADB_VERSION="10.11.3-r0"
ENV MARIADB_VERSION=${MARIADB_VERSION}

RUN adduser --shell /bin/false --disabled-password --gecos "MariaDB User" --home "/var/lib/mysql" "mysql" \
    && apk add --update --upgrade --no-cache bash openssl tzdata \
    && apk add --no-cache \
        "mariadb=${MARIADB_VERSION}" \
        "mariadb-backup=${MARIADB_VERSION}" \
        "mariadb-client=${MARIADB_VERSION}" \
        "mariadb-common=${MARIADB_VERSION}" \
        "mariadb-server-utils=${MARIADB_VERSION}" \
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

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>" \
      org.opencontainers.image.source="https://github.com/N0rthernL1ghts/mariadb" \
      org.opencontainers.image.description="MariaDB ${MARIADB_VERSION} - Alpine Build ${TARGETPLATFORM}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${MARIADB_VERSION}"