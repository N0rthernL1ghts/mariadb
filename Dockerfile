FROM ghcr.io/hairyhenderson/gomplate:v3.11.5-alpine AS gomplate

# Build rootfs
FROM scratch AS rootfs

# Copy overlay
COPY ["rootfs", "/"]

# Install gomplate
COPY --from=gomplate  ["/bin/gomplate", "/usr/bin/gomplate"]



# Final stage
FROM lscr.io/linuxserver/mariadb:latest

RUN set -eux \
    && apk add --no-cache openssl

COPY --from=rootfs ["/", "/"]

# Expose primary port, and also administrative port
EXPOSE 3306/TCP
EXPOSE 8385/TCP



LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>" \
      org.opencontainers.image.source="https://github.com/N0rthernL1ghts/mariadb" \
      org.opencontainers.image.description="MariaDB ${MARIADB_VERSION} - Based on lscr.io/linuxserver/mariadb:${BASE_IMAGE_VERSION}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${MARIADB_VERSION}"

ENV DATADIR="/var/lib/mysql"