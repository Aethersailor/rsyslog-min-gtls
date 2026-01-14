# rsyslog-min-gtls

Builds a minimal rsyslog image with gnutls (TLS/mTLS) support.

- Source: upstream rsyslog
- Modules included: imudp, imtcp, lmtcpsrv, lmnet, lmnetstrms, lmnsd_ptcp, lmnsd_gtls
- Default config: listens on TCP/UDP 1514 and logs to stdout
- Compatibility: imtcp accepts legacy StreamDriver* parameter names
