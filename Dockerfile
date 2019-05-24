FROM debian:stable-slim as dependencies1

WORKDIR /data

#su-exec
ARG SUEXEC_VERSION=v0.2
ARG SUEXEC_HASH=f85e5bde1afef399021fbc2a99c837cf851ceafa

ENV CFLAGS '-fPIC -O2 -g'
ENV CXXFLAGS '-fPIC -O2 -g'
ENV LDFLAGS '-static-libstdc++'

RUN apt-get update -qq && apt-get --no-install-recommends -yqq install \
        ca-certificates \
        g++ \
        g++-multilib \
        make \
        pkg-config \
        doxygen \
        git \
        curl \
        libtool-bin \
        autoconf \
        automake \
        patch \
        bzip2 \
        binutils-gold \
        bsdmainutils \
        python3 \
        build-essential \
        libtool \
        libprotobuf-dev protobuf-compiler \
        unzip > /dev/null \
    && cd /data \
    && echo "\e[32mbuilding: su-exec\e[39m" \
    && git clone --branch ${SUEXEC_VERSION} --single-branch --depth 1 https://github.com/ncopa/su-exec.git su-exec.git > /dev/null \
    && cd su-exec.git \
    && test `git rev-parse HEAD` = ${SUEXEC_HASH} || exit 1 \
    && make -j4 > /dev/null \
    && cp su-exec /data \
    && cd /data \
    && rm -rf /data/su-exec.git

FROM index.docker.io/xmrto/bitcoin:dependencies1 as builder
WORKDIR /data

ARG PROJECT_URL=https://github.com/bitcoin/bitcoin.git
ARG BRANCH=master
ARG BUILD_PATH=/bitcoin.git/build/release/bin

ENV BASE_DIR /usr/local


ENV CFLAGS '-fPIC -O2 -g'
ENV CXXFLAGS '-fPIC -O2 -g'
ENV LDFLAGS '-static-libstdc++'

RUN echo "\e[32mcloning: $PROJECT_URL on branch: $BRANCH\e[39m" \
    && git clone --branch "$BRANCH" --single-branch --recursive $PROJECT_URL bitcoin.git > /dev/null \
    && cd bitcoin.git \
    && echo "\e[32mbuilding static binaries\e[39m" \
    && ldconfig > /dev/null \
    && ./autogen.sh \
    && cd depends \
    && make -j4 HOST=x86_64-pc-linux-gnu NO_QT=1 NO_UPNP=1 \
    && cd .. \
    && ./configure --prefix=${PWD}/depends/x86_64-pc-linux-gnu --enable-glibc-back-compat LDFLAGS="$LDFLAGS" --without-miniupnpc --enable-reduce-exports --disable-bench --without-gui \
    && make -j4 HOST=x86_64-pc-linux-gnu NO_QT=1 NO_UPNP=1 \
    && echo "\e[32mcopy and clean up\e[39m" \
    && find /data -name "bitcoind" \
    && mv /data/bitcoin.git/src/bitcoind /data/ \
    && chmod +x /data/bitcoind \
    && mv /data/bitcoin.git/src/bitcoin-cli /data/ \
    && chmod +x /data/bitcoin-cli \
    && cd /data \
    && rm -rf /data/bitcoin.git \
    && apt-get purge -yqq \
        g++ \
        g++-multilib \
        make \
        pkg-config \
        doxygen \
        git \
        curl \
        libtool-bin \
        autoconf \
        automake \
        patch \
        bzip2 \
        binutils-gold \
        bsdmainutils \
        python3 \
        build-essential \
        libtool \
        libprotobuf-dev protobuf-compiler \
        unzip > /dev/null \
    && apt-get autoremove --purge -yqq > /dev/null \
    && apt-get clean > /dev/null \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt/* > /dev/null

FROM debian:stable-slim
COPY --from=builder /data/bitcoind /usr/local/bin/
COPY --from=builder /data/bitcoin-cli /usr/local/bin/
COPY --from=builder /data/su-exec /usr/local/bin/

RUN apt-get autoremove --purge -yqq > /dev/null \
    && apt-get clean > /dev/null \
    && rm -rf /var/tmp/* /tmp/* /var/lib/apt > /dev/null

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY inputrc /etc/inputrc

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
