FROM ruby:2.4.5-slim
ENV BUNDLER_VERSION=2.1.4
RUN <<EOR
  echo "deb http://archive.debian.org/debian/ stretch main contrib non-free
  deb http://archive.debian.org/debian-security stretch/updates main contrib non-free" > /etc/apt/sources.list
EOR
RUN apt-get update -qq && apt-get install -y -qq nodejs libpq-dev\
  git curl wget build-essential libssl-dev libreadline-dev zlib1g-dev
RUN gem install bundler -v 2.1.4
WORKDIR /app
COPY . ./
RUN cp config/database.yml.example config/database.yml
#RUN bundle config build.nokogiri --use-system-libraries
RUN bundle check || bundle install
#ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]
