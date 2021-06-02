FROM alpine:3.12

RUN apk update && apk upgrade \
  && apk add ca-certificates \
  && rm -rf /var/cache/apk/*

RUN addgroup -g 1000 -S fn && adduser -S -u 1000 -G fn fn

RUN apk add --no-cache libxml2 libxslt libevent libffi glib ncurses readline \
    openssl yaml zlib curl libpq ruby ruby-io-console ruby-bundler \
    ruby-bigdecimal