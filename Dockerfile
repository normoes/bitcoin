FROM debian:stable-slim as builder

WORKDIR /data

RUN apt-get update -qq && apt-get -y install --no-install-recommends \
        ca-certificates \
        build-essential \
        git \
        curl

ARG PROTOCOL
ARG BINARIES_URL
# ARG ACCESS_TOKEN
ARG DEPLOY_TOKEN
ARG DEPLOY_USER

RUN git clone --depth 1 $PROTOCOL$DEPLOY_USER:$DEPLOY_TOKEN@$BINARIES_URL bitcoin \
    && cp bitcoin/bitcoind /data \
    && cp bitcoin/bitcoin-cli /data \
    && chmod 755 /data/bitcoind \
    && chmod 755 /data/bitcoin-cli
 
RUN cd /data \
    && git clone https://github.com/ncopa/su-exec.git su-exec-clone \
    && cd su-exec-clone \
    && make \
    && cp su-exec /data

RUN apt-get purge -y \
        git \
        curl \
        ca-certificates \
        build-essential \
    && apt-get autoremove --purge -y \
    && apt-get clean \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt \
    && rm -rf /data/su-exec-clone \
    && rm -rf /data/bitcoin

FROM debian:stable-slim
COPY --from=builder /data/bitcoind /usr/local/bin/
COPY --from=builder /data/bitcoin-cli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /bitcoin

RUN bitcoind --version > /version.txt \
    && cat /etc/os-release > /system.txt \
    && ldd $(command -v bitcoind) > /dependencies.txt

VOLUME ["/bitcoin"]

ENV USER_ID 1000
ENV RPC_USER=local
ENV RPC_PASSWD=local
ENV RPC_ALLOW_IP=0.0.0.0/0
ENV RPC_BIND=0.0.0.0
ENV RPC_PORT=18332
ENV P2P_PORT=18333
ENV MAX_CONNECTIONS=125

ENTRYPOINT ["/entrypoint.sh"]
