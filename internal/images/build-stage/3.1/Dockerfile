FROM --platform=$TARGETPLATFORM ocr-docker-remote.artifactory.oci.oraclecorp.com/os/oraclelinux:8-slim

ENV GEM_HOME=/usr/lib/ruby/gems
ENV GEM_PATH=/usr/lib/ruby/gems

RUN microdnf module enable ruby:3.1 && \
      microdnf install ruby ruby-devel rubygems \
            make gcc glibc system-rpm-config openssl-devel && \
      microdnf install --enablerepo=ol8_codeready_builder libyaml-devel && \
      microdnf module reset ruby && \
      microdnf clean all && \
      mkdir -p /usr/lib/ruby/gems && \
      echo "gem: --install-dir=$GEM_HOME  --bindir /usr/local/bin" > ~/.gemrc

RUN gem install --no-document bundler rake & \
   gem install --no-document stringio -v '~> 3.1.0, >= 3.1.0' && \
   gem install --no-document rdoc -v '~> 6.4.1.1, >= 6.4.1.1' && \
   gem install --no-document openssl -v '~> 3.2.0, >= 3.2.0' -- --with-openssl-dir=/usr && \
   gem install --no-document prism -v '~> 1.0' && \
   gem cleanup

# stringio-3.0.1 and openssl-3.0.1 are default gems so the gem cli won't
# uninstall them even though we've replaced them with a newer versions
# Manually deleting them works
RUN find / -name '*stringio-3.0.1*' -exec rm -rf '{}' + && \
   find / -name '*openssl-3.0.1*' -exec rm -rf '{}' + && \
   rm -rf $(ruby -e 'print Gem.default_specifications_dir')/prism-0.19*.gemspec

CMD ["ruby", "-v"]

