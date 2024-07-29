FROM --platform=$TARGETPLATFORM container-registry.oracle.com/os/oraclelinux:8-slim

ENV GEM_HOME=/usr/lib/ruby/gems
ENV GEM_PATH=/usr/lib/ruby/gems

RUN microdnf module enable ruby:3.3 && \
      microdnf install ruby ruby-devel rubygems \
            make gcc glibc system-rpm-config openssl-devel && \
      microdnf install --enablerepo=ol8_codeready_builder libyaml-devel && \
      microdnf module reset ruby && \
      microdnf clean all && \
      mkdir -p /usr/lib/ruby/gems && \
      echo "gem: --install-dir=$GEM_HOME  --bindir /usr/local/bin" > ~/.gemrc

RUN gem install --no-document bundler rake && \
    gem cleanup

CMD ["ruby", "-v"]