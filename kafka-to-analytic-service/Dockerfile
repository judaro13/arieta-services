FROM ruby:alpine

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

# Update and install all of the required packages.
# At the end, remove the apk cache
#RUN apk update && \
#    apk upgrade && \
#    apk add $BUILD_PACKAGES && \
#    apk add $RUBY_PACKAGES && \
#    rm -rf /var/cache/apk/*

RUN mkdir /usr/app
RUN mkdir /usr/app/public
WORKDIR /usr/app

COPY Gemfile /usr/app/
COPY Gemfile.lock /usr/app/
COPY service.rb /usr/app/

RUN bundle install
EXPOSE 3000

CMD ["ruby", "service.rb"]
