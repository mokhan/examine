FROM ruby:alpine

RUN apk add git
RUN gem install bundler -v '~> 2.0'
RUN mkdir -p /examine
WORKDIR /examine
COPY . .
RUN bundle install --jobs "$(nproc)" --quiet
ENTRYPOINT ["bundle", "exec", "./exe/examine"]
