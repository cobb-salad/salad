FROM openjdk:8-jre-alpine

# Install required packages
RUN apk add --no-cache \
    ca-certificates \
    bash \
    su-exec \
    gnupg \
    curl

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; \
      chmod +x ./kubectl; \
      mv ./kubectl /usr/local/bin/kubectl

# Kafka, Scala Version
ENV KAFKA_VERSION=2.1.1 SCALA_VERSION=2.12

# Create kafka installation path
ENV KAFKA_PATH=/opt/kafka
RUN mkdir -p $KAFKA_PATH

ENV KAFKA_CONF_DIR=/conf \
    KAFKA_DATA_DIR=/data

RUN mkdir -p "$KAFKA_CONF_DIR" "$KAFKA_DATA_DIR"

# Download Apache Kafka, verify its PGP signature, untar and clean up
RUN set -ex; \
    curl -s -o KEYS https://www.apache.org/dist/kafka/KEYS; \
    gpg --import KEYS && rm KEYS; \
    curl -SLs -o kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz "https://www.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz"; \
    curl -s -o kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc "https://www.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc"; \
    gpg --verify kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz.asc kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz; \
    tar xzf kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz --strip-components=1 -C /opt/kafka; \
    rm kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz;

WORKDIR $KAFKA_PATH

ENV PATH=$PATH:$KAFKA_PATH/bin

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["kafka-server-start.sh","/etc/kafka/server.properties"]

