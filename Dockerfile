ARG ALPINE_VERSION=3.18
FROM alpine:${ALPINE_VERSION}

WORKDIR /opt/utils

ARG PG_VERSION=16

RUN apk update && \
    apk add postgresql${PG_VERSION}-client gnupg aws-cli curl

COPY src/ .

RUN chmod +x -R /opt/utils/

ENTRYPOINT ["/opt/utils/entrypoint.sh"]
