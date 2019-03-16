#!/bin/sh

set -e

mkdir -p /etc/kafka
cp ${KAFKA_CONF_DIR}/* /etc/kafka
export BROKER_SERVER_ID=${HOSTNAME##*-}
export DATA_DIR=${KAFKA_DATA_DIR/\//\\\/}
sed -i "s/#init#log.dirs=#init#/log.dirs=$DATA_DIR/" /etc/kafka/server.properties
sed -i "s/#init#broker.id=#init#/broker.id=$BROKER_SERVER_ID/" /etc/kafka/server.properties

LABEL="kafka-broker-id=$BROKER_SERVER_ID"

if [ ! -z "$LABEL" ]; then
  kubectl -n $POD_NAMESPACE label pod $POD_NAME $LABEL --overwrite=true
fi

OUTSIDE_HOST=$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  if [ $? -ne 0 ]; then
    echo "Outside (i.e. cluster-external access) host lookup command failed"
  else
    OUTSIDE_PORT=3240${BROKER_SERVER_ID}
    sed -i "s|#init#advertised.listeners=OUTSIDE://#init#|advertised.listeners=OUTSIDE://${OUTSIDE_HOST}:${OUTSIDE_PORT}|" /etc/kafka/server.properties
    ANNOTATIONS="$ANNOTATIONS kafka-listener-outside-host=$OUTSIDE_HOST kafka-listener-outside-port=$OUTSIDE_PORT"
  fi

  if [ ! -z "$ANNOTATIONS" ]; then
    kubectl -n $POD_NAMESPACE annotate pod $POD_NAME $ANNOTATIONS || echo "Failed to annotate $POD_NAMESPACE.$POD_NAME - RBAC issue?"
  fi

exec "$@"
