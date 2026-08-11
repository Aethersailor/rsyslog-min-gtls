#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
  image="$1"
  docker run --rm "$image" /bin/sh -ec '
    test -x /usr/sbin/rsyslogd
    test -f /usr/lib/rsyslog/lmnsd_gtls.so
    /usr/sbin/rsyslogd -N1 -iNONE -M/usr/lib/rsyslog -f /etc/rsyslog.conf
  '
else
  test -x /usr/sbin/rsyslogd
  test -f /usr/lib/rsyslog/lmnsd_gtls.so
  /usr/sbin/rsyslogd -N1 -iNONE -M/usr/lib/rsyslog -f /etc/rsyslog.conf
fi

echo "smoke test OK"
