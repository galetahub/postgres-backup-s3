ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}

WORKDIR /opt/utils

RUN apk update && \
    apk add postgresql-client gnupg aws-cli curl

COPY src/ .

CMD ["sh", "/opt/utils/run.sh"]
