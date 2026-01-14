# ===== Builder =====
FROM debian:stable-slim AS builder

ARG RSYSLOG_REF=v8.2510.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git build-essential autoconf automake libtool pkg-config \
    flex bison \
    libgnutls28-dev libgcrypt20-dev libzstd-dev zlib1g-dev \
    libestr-dev libfastjson-dev liblogging-stdlog-dev librelp-dev \
    uuid-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch "${RSYSLOG_REF}" https://github.com/rsyslog/rsyslog.git .

COPY scripts/build-rsyslog.sh /build-rsyslog.sh
RUN chmod +x /build-rsyslog.sh && /build-rsyslog.sh

# 收集运行时所需文件：rsyslogd + 关键模块 + 依赖库
RUN mkdir -p /out/usr/sbin /out/usr/lib/rsyslog /out/etc/ssl/certs /out/lib /out/usr/lib /out/usr/lib/x86_64-linux-gnu

# rsyslogd
RUN cp -a /usr/local/sbin/rsyslogd /out/usr/sbin/

# 模块（只复制我们需要的）
RUN cp -a /usr/local/lib/rsyslog/imudp.so /out/usr/lib/rsyslog/ \
 && cp -a /usr/local/lib/rsyslog/imtcp.so /out/usr/lib/rsyslog/ \
 && cp -a /usr/local/lib/rsyslog/lmnetstrms.so /out/usr/lib/rsyslog/ \
 && cp -a /usr/local/lib/rsyslog/lmnsd_gtls.so /out/usr/lib/rsyslog/

# CA bundle（用于验证客户端证书链等）
RUN cp -a /etc/ssl/certs/ca-certificates.crt /out/etc/ssl/certs/

# 复制动态库依赖（只把 rsyslogd 运行必须的库带走）
RUN ldd /usr/local/sbin/rsyslogd | awk '{print $3}' | grep -E '^/' | sort -u \
 | xargs -I{} cp -a --parents {} /out

# 再把模块依赖库也补齐（避免运行时报缺库）
RUN for m in /usr/local/lib/rsyslog/imudp.so /usr/local/lib/rsyslog/imtcp.so /usr/local/lib/rsyslog/lmnetstrms.so /usr/local/lib/rsyslog/lmnsd_gtls.so; do \
      ldd "$m" | awk '{print $3}' | grep -E '^/' | sort -u; \
    done | sort -u | xargs -I{} cp -a --parents {} /out

# 尽可能 strip，缩小体积
RUN strip --strip-unneeded /out/usr/sbin/rsyslogd || true \
 && strip --strip-unneeded /out/usr/lib/rsyslog/*.so || true \
 && find /out -type f -name "*.a" -delete || true

# ===== Runtime =====
FROM debian:stable-slim AS runtime

# 运行时目录
RUN mkdir -p /var/log /etc/rsyslog.d /etc/rsyslog/tls /etc/rsyslog/mtls

COPY --from=builder /out/ /

# rsyslog 默认模块路径：/usr/lib/rsyslog
ENV RSYSLOG_MODDIR=/usr/lib/rsyslog

# 前台运行
CMD ["/usr/sbin/rsyslogd","-n","-iNONE","-M/usr/lib/rsyslog"]
