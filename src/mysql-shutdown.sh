#!/usr/bin/with-contenv sh
# shellcheck shell=sh
set -e

mariadb << EOF
   SET GLOBAL innodb_fast_shutdown=0;
   SET GLOBAL innodb_max_dirty_pages_pct=0;
EOF

mariadb-admin shutdown -v
