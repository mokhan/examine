FROM docker:stable
RUN apk add ruby git curl
RUN gem install bundler -v '~> 2.0' --no-document
RUN wget https://github.com/arminc/clair-scanner/releases/download/v12/clair-scanner_linux_386 && \
  mv clair-scanner_linux_386 /usr/local/bin/clair-scanner && \
  chmod +x /usr/local/bin/clair-scanner
RUN mkdir -p /examine
WORKDIR /examine
COPY . .
RUN bundle install --jobs "$(nproc)" --quiet
ENTRYPOINT ["bundle", "exec", "./exe/examine"]
