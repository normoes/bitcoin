#!/bin/bash

OPTIONS="-server -printtoconsole -logtimestamps -port=$P2P_PORT -maxconnections=$MAX_CONNECTIONS -rpcbind=$RPC_BIND -rpcport=$RPC_PORT -rpcuser=$RPC_USER -rpcpassword=$RPC_PASSWD -rpcallowip=$RPC_ALLOW_IP"

BITCOIND="bitcoind $@ $OPTIONS"

#3 bitcoind
if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $BITCOIND
## bitcoin-cli
elif [[ "$1" = bitcoin-cli* ]]; then
  set -- "$@"
fi

echo "$@"

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (Dockerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false bitcoin &> /dev/null
  exec su-exec bitcoin $@
fi

exec $@
