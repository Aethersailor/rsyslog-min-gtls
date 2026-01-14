#!/usr/bin/env bash
set -euo pipefail

# 仅做存在性检查
test -x /usr/sbin/rsyslogd
test -f /usr/lib/rsyslog/lmnsd_gtls.so
echo "smoke test OK"
