FROM --platform=$TARGETPLATFORM ocr-docker-remote.artifactory.oci.oraclecorp.com/os/oraclelinux:8-slim

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
    gem install --no-document prism -v '~> 1.0' && \
    gem cleanup

# prism-0.19.0 is a default gem so the gem cli won't
# uninstall it even though we've replaced it with a newer version
# Manually deleting them works
RUN rm -rf '/usr/share/gems/specifications/default/prism-0.19.0.gemspec' \;

CMD ["ruby", "-v"]