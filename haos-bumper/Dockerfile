ARG PY_VERSION=3.14.5-alpine3.22
ARG UV_VERSION=python3.14-alpine

FROM ghcr.io/astral-sh/uv:${UV_VERSION} AS uv_source
FROM python:${PY_VERSION} AS builder

COPY --from=uv_source /usr/local/bin/uv /usr/local/bin/uvx /bin/

RUN apk add --no-cache \
  bash \
  git \
  openssl \
  gcc \
  musl-dev \
  linux-headers

WORKDIR /bumper
COPY . .
RUN uv sync --no-dev --no-editable --no-cache

FROM python:${PY_VERSION}

LABEL org.opencontainers.image.source=https://github.com/vvd214/bumper
LABEL org.opencontainers.image.description="Bumper HAOS add-on"
LABEL org.opencontainers.image.licenses=GPLv3

RUN addgroup -S -g 1000 bumper && adduser -S -u 1000 -G bumper bumper
COPY --from=builder --chown=bumper:bumper /bumper/.venv /bumper/.venv
COPY haos-bumper/run.sh /run.sh
RUN chmod a+x /run.sh

WORKDIR /bumper
ENTRYPOINT ["/run.sh"]
