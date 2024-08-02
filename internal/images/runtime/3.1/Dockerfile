FROM --platform=$TARGETPLATFORM ocr-docker-remote.artifactory.oci.oraclecorp.com/os/oraclelinux:8-slim

ENV GEM_HOME=/usr/lib/ruby/gems
ENV GEM_PATH=/usr/lib/ruby/gems

RUN microdnf update && \
      microdnf module enable ruby:3.1 && \
      microdnf install ruby rubygems && \
      microdnf module reset ruby && \
      microdnf clean all && \
      mkdir -p /usr/lib/ruby/gems && \
      echo "gem: --install-dir=$GEM_HOME  --bindir /usr/local/bin" > ~/.gemrc

# stringio-3.0.1 and openssl-3.0.1 are default gems so the only way to get rid of them is to manually delete
# rdoc-6.4.0 doesn't appear to be 'officially' installed, gem uninstall claims it doesn't exist but the files are there
RUN microdnf install findutils && \
    find / -name '*stringio-3.0.1*' -exec rm -rf '{}' + && \
    find / -name '*openssl-3.0.1*' -exec rm -rf '{}' + && \
    find / -name '*rdoc-6.4.0*' -exec rm -rf '{}' + && \
    microdnf remove findutils && \
    microdnf clean all

RUN groupadd --system --gid 1000 fn && adduser --uid 1000 --gid 1000 fn

CMD ["ruby", "-v"]
