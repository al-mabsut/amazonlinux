# Building an Phoenix (Elixir) Release targeting Amazon Linux for EC2
# By https://github.com/treygriffith
# Original by the Phoenix team: https://hexdocs.pm/phoenix/releases.html#containers
#
# Note: Build context should be the application root
# Build Args:
# OTP_VERSION - the OTP version to target, like 23.0
# ELIXIR_VERSION - the Elixir version to target, like 1.10.4
#
# If you have other environment variables in config/prod.secret.exs, add them as `ARG`s in this file

FROM amazonlinux:2 AS build

# https://gist.github.com/techgaun/335ef6f6abb5a254c66d73ac6b390262
RUN yum -y groupinstall "Development Tools" && \
  yum -y install openssl-devel ncurses-devel

# Install Erlang
ARG OTP_VERSION
WORKDIR /tmp
RUN mkdir -p otp && \
  curl -LS "https://github.com/erlang/otp/archive/refs/tags/OTP-${OTP_VERSION}.tar.gz" --output otp.tar.gz && \
  tar xfz otp.tar.gz -C otp --strip-components=1
WORKDIR otp/
RUN ./configure && make && make install

# Install Elixir
ARG ELIXIR_VERSION
ENV LC_ALL en_US.UTF-8
WORKDIR /tmp
RUN mkdir -p elixir && \
  curl -LS "https://github.com/elixir-lang/elixir/archive/refs/tags/v${ELIXIR_VERSION}.tar.gz" --output elixir.tar.gz && \
  tar xfz elixir.tar.gz -C elixir --strip-components=1
WORKDIR elixir/
RUN make install -e PATH="${PATH}:/usr/local/bin"

# Install node
RUN curl -sL https://rpm.nodesource.com/setup_16.x | bash - && \
  yum install nodejs -y

# prepare build dir
WORKDIR /app

VOLUME /var/lib/docker
# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
# ENV MIX_ENV=prod

# install mix dependencies
# COPY mix.exs mix.lock ./
# COPY config config
# RUN mix do deps.get, deps.compile

# build assets
# COPY assets/package.json assets/package-lock.json assets/
# RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

# COPY priv priv
# COPY assets assets
# RUN npm run --prefix ./assets deploy
# RUN mix phx.digest

# compile and build release
# COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
# RUN mix do compile, release