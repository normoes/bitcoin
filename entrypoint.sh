#!/bin/bash

# rpc login options
echo "$RPC_LOGIN"
if [ -n "$RPC_USER" -a -n "$RPC_PASSWD" ]; then
    RPC_LOGIN="-rpcuser=$RPC_USER -rpcpassword=$RPC_PASSWD"
elif [ -n "$RPC_AUTH" ]; then
    RPC_LOGIN="-rpcauth=$RPC_AUTH"
fi

echo "$RPC_LOGIN"

OPTIONS="-server -printtoconsole -logtimestamps -port=$P2P_PORT -maxconnections=$MAX_CONNECTIONS -rpcbind=$RPC_BIND -rpcport=$RPC_PORT $RPC_LOGIN -rpcallowip=$RPC_ALLOW_IP"
echo "$OPTIONS"

BITCOIND="bitcoind $@ $OPTIONS"

## bitcoind
if [[ "${1:0:1}" = '-' ]]  || [[ -z "$@" ]]; then
  set -- $BITCOIND
## bitcoin-cli
elif [[ "$1" = bitcoin-cli* ]]; then
  set -- "$@"
fi

# allow the container to be started with `--user
if [ "$(id -u)" = 0 ]; then
  # USER_ID defaults to 1000 (Dockerfile)
  adduser --system --group --uid "$USER_ID" --shell /bin/false bitcoin &> /dev/null
  exec su-exec bitcoin $@
fi

exec $@
