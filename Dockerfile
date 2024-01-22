FROM ruby:2.6.5

ENV APP_ROOT /var/app

ARG RAILS_ENV
ENV RACK_ENV $RAILS_ENV
ENV RAILS_SERVE_STATIC_FILES true

RUN apt-get update -qq && \
    apt-get install -qq -y build-essential --no-install-recommends && \
    mkdir -p $APP_ROOT

WORKDIR $APP_ROOT
ADD Gemfile* $APP_ROOT/

RUN gem install bundler:2.0.2 && \
    bundle install

ADD . $APP_ROOT

EXPOSE 4567

CMD ["ruby", "app.rb", "-o", "0.0.0.0"]