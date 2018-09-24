FROM ruby:2.5-slim
MAINTAINER David Martin <david.martin@bizneo.com>
RUN gem install bundler

RUN apt-get clean && apt-get update && \
  apt-get install libcurl-ocaml-dev libmagickwand-dev webp -y --force-yes --fix-missing \
  build-essential \
  && apt-get clean autoclean -y && rm -rf /var/lib/{apt,dpkg,cache,log}

RUN mkdir -p /app
WORKDIR /app
