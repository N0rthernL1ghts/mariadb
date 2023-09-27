ARG MARIADB_VERSION="10.11.5"

FROM ghcr.io/hairyhenderson/gomplate:v3.11.5-alpine AS gomplate

# Build rootfs
FROM scratch AS rootfs

# Copy overlay
COPY ["rootfs", "/"]

# Copy scripts
COPY ["/src/", "/app/"]

# Install gomplate
COPY --from=gomplate  ["/bin/gomplate", "/usr/bin/gomplate"]



# Final stage
ARG MARIADB_VERSION
FROM --platform=${TARGETPLATFORM} lscr.io/linuxserver/mariadb:${MARIADB_VERSION}

RUN set -eux \
    && apk add --no-cache openssl

COPY --from=rootfs ["/", "/"]

# Expose primary port, and also administrative port
EXPOSE 3306/TCP
EXPOSE 8385/TCP


ARG MARIADB_VERSION
LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>" \
      org.opencontainers.image.source="https://github.com/N0rthernL1ghts/mariadb" \
      org.opencontainers.image.description="MariaDB ${MARIADB_VERSION} (${TARGETPLATFORM}) - Based on lscr.io/linuxserver/mariadb:${MARIADB_VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${MARIADB_VERSION}" \
      build_version="Custom"


ENV MARIADB_VERSION="${MARIADB_VERSION}"
ENV DATADIR="/var/lib/mysql"
ENV FORCE_CONFIG_OVERWRITE="0"
ENV LSIO_FIRST_PARTY=false