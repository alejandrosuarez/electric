ARG ELIXIR_VERSION=1.17.2
ARG OTP_VERSION=27.0.1
ARG DEBIAN_VERSION=bookworm-20240722-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder
LABEL maintainer="info@electric-sql.com"

RUN apt-get update -y && \
    apt-get install -y build-essential git curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV=prod

WORKDIR /app

COPY mix.* /app/
COPY config/config.exs /app/config/
COPY config/prod.exs /app/config/
RUN mix deps.get --only $MIX_ENV --check-locked
RUN mix deps.compile
RUN mix assets.setup

COPY config/*runtime.exs /app/config/

COPY lib /app/lib/
RUN mix compile

COPY assets /app/assets/
COPY priv /app/priv/
RUN mix assets.deploy

COPY rel /app/rel/

RUN mix release

FROM ${RUNNER_IMAGE} AS runner_setup

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

FROM runner_setup AS runner

ARG RELEASE_NAME=electric_phoenix_example

COPY --from=builder /app/_build/prod/rel/${RELEASE_NAME} ./
RUN mv /app/bin/${RELEASE_NAME} /app/bin/entrypoint

CMD ["/app/bin/server"]

