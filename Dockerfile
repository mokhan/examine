FROM docker:stable
RUN apk add ruby git
RUN gem install bundler -v '~> 2.0' --no-document
RUN mkdir -p /examine
WORKDIR /examine
COPY . .
RUN bundle install --jobs "$(nproc)" --quiet
ENTRYPOINT ["bundle", "exec", "./exe/examine"]
