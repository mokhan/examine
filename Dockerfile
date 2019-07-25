FROM docker:stable
ENV PACKAGES build-base ruby ruby-dev ruby-json ruby-etc git curl
RUN wget https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_amd64 && \
  mv clair-scanner_linux_amd64 /usr/local/bin/clair-scanner && \
  chmod +x /usr/local/bin/clair-scanner
RUN mkdir -p /examine
WORKDIR /examine
COPY . .
RUN apk update && \
  apk upgrade && \
  apk add $PACKAGES && \
  rm -fr /var/cache/apk/* && \
  gem install bundler:'~> 2.0' --no-document && \
  bundle install --jobs "$(nproc)" --quiet --path vendor/bundle && \
  apk del build-base
ENTRYPOINT ["bundle", "exec", "./exe/examine"]
