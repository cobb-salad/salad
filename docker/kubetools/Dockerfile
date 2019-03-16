FROM alpine:3.7

RUN apk add --no-cache --virtual .build-deps \
        ca-certificates \
        curl;

### Install latest version of kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl; \
      chmod +x ./kubectl; \
      mv ./kubectl /usr/local/bin/kubectl
