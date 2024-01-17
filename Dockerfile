FROM ruby:2.6.5

ENV APP_ROOT /var/app

ARG GIFMACHINE_PASSWORD="password123"
ENV GIFMACHINE_PASSWORD $GIFMACHINE_PASSWORD

ARG RACK_ENV="development"
ENV RAILS_ENV $RACK_ENV
ENV RACK_ENV $RACK_ENV

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