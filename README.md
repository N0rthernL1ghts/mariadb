# MariaDB
#### Lightweight docker image for MariaDB with advanced features for automated provisioning


These are docker images for [MariaDB](https://mariadb.org) database running on an [Alpine Linux container](https://registry.hub.docker.com/u/webhippie/alpine/).

Originally a standalone fork of [dockhippie/mariadb](https://github.com/dockhippie/mariadb), which has completely diverged from the original and eventually rebased to [linuxserver/docker-mariadb](https://github.com/linuxserver/docker-mariadb) image. 

Important: While based on [linuxserver/docker-mariadb](https://github.com/linuxserver/docker-mariadb), this image is not compatible with the original image. It has been heavily modified and is not intended to be used as a drop-in replacement.


## Versions

* ghcr.io/n0rthernl1ghts/mariadb:10.6
* ghcr.io/n0rthernl1ghts/mariadb:10.11
* ghcr.io/n0rthernl1ghts/mariadb:11.4
* ghcr.io/n0rthernl1ghts/mariadb:latest

## Volumes

* /config
* /var/lib/mysql


## Ports

* 3306
* 8385 (for maintenance purposes - immune to max_connections limit)

WARNING: NEVER expose these ports to the public internet or LAN. Starting this container with host networking will do that.

## Available environment variables

Image configurable environment variables:
```bash
# Linuxserver.io baseimage specific
PUID = 1000 
PGID = 1000

# This image specific
MARIADB_ROOT_PASSWORD = example-root-password
MARIADB_INIT_DATABASES = app,app2,app3
MARIADB_INIT_USERS = lorem,ipsum,dolor,foo  # Format: user1,user2,user3
MARIADB_USER_FOO_PASSWORD = example-password-for-foo
FORCE_CONFIG_OVERWRITE = 0 # Force overwriting of existing config file that is usually generated on first run
```
If there is no password set for users on the list, a random password will be generated and printed to the STDOUT. Password is also stored in the `/config/.username.password` file. You should delete this file afterwards.


MariaDB specific variables:
```bash
MARIADB_CLIENT_DEFAULT_CHARACTER_SET = utf8mb4
MARIADB_MYSQLD_SAFE_NICE = 0
MARIADB_KEY_BUFFER_SIZE = 128M
MARIADB_MAX_CONNECTIONS = 100
MARIADB_CONNECT_TIMEOUT = 5
MARIADB_WAIT_TIMEOUT = 600
MARIADB_MAX_ALLOWED_PACKET = 16M
MARIADB_THREAD_CACHE_SIZE = 128
MARIADB_THREAD_STACK = 192K
MARIADB_SORT_BUFFER_SIZE = 4M
MARIADB_BULK_INSERT_BUFFER_SIZE = 16M
MARIADB_TMP_TABLE_SIZE = 32M
MARIADB_MAX_HEAP_TABLE_SIZE = 32M
MARIADB_CHARACTER_SET_SERVER = utf8mb4
MARIADB_TRANSACTION_ISOLATION = READ-COMMITTED
MARIADB_BINLOG_FORMAT = MIXED
MARIADB_MYISAM_RECOVER = BACKUP
MARIADB_TABLE_OPEN_CACHE = 400
MARIADB_MYISAM_SORT_BUFFER_SIZE = 512M
MARIADB_CONCURRENT_INSERT = 2
MARIADB_READ_BUFFER_SIZE = 2M
MARIADB_READ_RND_BUFFER_SIZE = 1M
MARIADB_QUERY_CACHE_LIMIT = 128K
MARIADB_QUERY_CACHE_SIZE = 64M
MARIADB_QUERY_CACHE_TYPE = DEMAND
MARIADB_CONSOLE = 1
MARIADB_LOG_WARNINGS = 2
MARIADB_SLOW_QUERY_LOG = 1
MARIADB_LONG_QUERY_TIME = 5
MARIADB_EXPIRE_LOG_DAYS = 10
MARIADB_MAX_BINLOG_SIZE = 100M
MARIADB_DEFAULT_STORAGE_ENGINE = InnoDB
MARIADB_INNODB_BUFFER_POOL_SIZE = 256M
MARIADB_INNODB_LOG_BUFFER_SIZE = 8M
MARIADB_INNODB_FILE_PER_TABLE = 1
MARIADB_INNODB_OPEN_FILES = 400
MARIADB_INNODB_IO_CAPACITY = 400
MARIADB_INNODB_FLUSH_METHOD = O_DIRECT
MARIADB_MYSQLDUMP_MAX_ALLOWED_PACKET = 16M
MARIADB_ISAMCHK_KEY_BUFFER = 16M
```

## Container healthcheck

Run `healthcheck` script to check if the container is healthy. Defined in your `compose.yaml` file like this:
```bash
    healthcheck:
      test: ["CMD", "/usr/bin/healthcheck"]
      interval: 30s
      timeout: 20s
      retries: 3
```

## Inherited environment variables

* [linuxserver/docker-mariadb](https://github.com/linuxserver/docker-mariadb)


## Contributing

Fork -> Patch -> Push -> Pull Request


## Authors

* [Aleksandar Puharic](https://github.com/xZero707)


## License

MIT


## Copyright

```
Copyright (c) 2023 Aleksandar Puharic  <https://www.puharic.com>
```
