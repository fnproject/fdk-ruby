FROM --platform=$TARGETPLATFORM ocr-docker-remote.artifactory.oci.oraclecorp.com/os/oraclelinux:8-slim

ENV GEM_HOME=/usr/lib/ruby/gems
ENV GEM_PATH=/usr/lib/ruby/gems

RUN microdnf update && \
      microdnf module enable ruby:3.3 && \
      microdnf install ruby rubygems && \
      microdnf module reset ruby && \
      microdnf clean all && \
      mkdir -p /usr/lib/ruby/gems && \
      echo "gem: --install-dir=$GEM_HOME  --bindir /usr/local/bin" > ~/.gemrc

# prism-0.19.0 is a default gem so the gem cli won't
# uninstall it even though we've replaced it with a newer version
# Manually deleting them works
RUN rm -rf $(ruby -e 'print Gem.default_specifications_dir')/prism-0.19*.gemspec

RUN groupadd --system --gid 1000 fn && adduser --uid 1000 --gid 1000 fn

CMD ["ruby", "-v"]
