FROM docker-remote.artifactory.oci.oraclecorp.com/alpine:3.12

RUN apk add --no-cache curl git make \
    libssl1.1 build-base libxml2-dev libxslt-dev libbz2 libevent-dev libffi-dev glib-dev ncurses-dev readline-dev yaml-dev zlib-dev \
    libpq sqlite-dev postgresql-dev \
    ruby-dev ruby ruby-io-console ruby-bundler

RUN gem install --no-document bundler
