FROM --platform=$TARGETPLATFORM container-registry.oracle.com/os/oraclelinux:8-slim

ENV GEM_HOME=/usr/lib/ruby/gems
ENV GEM_PATH=/usr/lib/ruby/gems

RUN microdnf module enable ruby:3.1 && \
      microdnf install ruby rubygems && \
      microdnf module reset ruby && \
      microdnf clean all && \
      mkdir -p /usr/lib/ruby/gems && \
      echo "gem: --install-dir=$GEM_HOME  --bindir /usr/local/bin" > ~/.gemrc

RUN groupadd --system --gid 1000 fn && adduser --uid 1000 --gid 1000 fn

CMD ["ruby", "-v"]
