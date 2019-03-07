#!/bin/bash

set -e

# Allow the container to be started with `--user`
#if [[ "$1" = 'zkServer.sh' && "$(id -u)" = '0' ]]; then
#    chown -R "$ZOO_USER" "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR" "$ZOO_CONF_DIR"
#    exec su-exec "$ZOO_USER" "$0" "$@"
#fi

[ -z "$ID_OFFSET" ] && ID_OFFSET=1
export ZOOKEEPER_SERVER_ID=$((${HOSTNAME##*-} + $ID_OFFSET ))
echo "${ZOOKEEPER_SERVER_ID:-1}" | tee ${ZOO_DATA_DIR}/myid

exec "$@"
