FROM alpine:3.4
MAINTAINER Xabier de Zuazo "xabier@zuazo.org"

ENV PROXYCHAINS_CONF=/etc/proxychains/proxychains.conf \
    TOR_CONF=/etc/tor/torrc \
    TOR_LOG_DIR=/var/log/s6/tor \
    DNSMASQ_CONF=/etc/dnsmasq.conf \
    DNSMASQ_LOG_DIR=/var/log/s6/dnsmasq

RUN echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' >> \
      /etc/apk/repositories && \
    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/community' >> \
      /etc/apk/repositories && \
    apk add --update \
      dnsmasq \
      openssl \
      proxychains-ng \
      s6 \
      tor@edge && \
    rm -rf /var/cache/apk/*

COPY etc/torrc $TOR_CONF
COPY etc/proxychains/proxychains.conf $PROXYCHAINS_CONF
COPY etc/dnsmasq.conf $DNSMASQ_CONF
COPY etc/s6 /etc/s6
COPY bin/tor_boot /usr/bin/tor_boot
COPY bin/tor_wait /usr/bin/tor_wait
COPY bin/proxychains_wrapper /usr/bin/proxychains_wrapper

RUN mkdir -p "$TOR_LOG_DIR" "$DNSMASQ_LOG_DIR" && \
    chown tor $TOR_CONF && \
    chmod 0644 $PROXYCHAINS_CONF && \
    chmod 0755 \
      /etc/s6/*/log/run \
      /etc/s6/*/run \
      /usr/bin/tor_boot \
      /usr/bin/tor_wait \
      /usr/bin/proxychains_wrapper

ENTRYPOINT ["/usr/bin/proxychains_wrapper"]
CMD ["/bin/sh"]
