#!/usr/bin/env sh
set -e

mysql << EOF
   SET GLOBAL innodb_fast_shutdown=0;
   SET GLOBAL innodb_max_dirty_pages_pct=0;
EOF

mysqladmin shutdown -v
