FROM ruby:3.0.4-alpine

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . ./

ENV PORT 5000
EXPOSE $PORT
CMD ["sh", "-c", "bundle exec rackup --host=0.0.0.0 --port=$PORT"]
