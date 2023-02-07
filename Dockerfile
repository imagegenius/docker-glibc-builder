# syntax=docker/dockerfile:1

FROM ubuntu

LABEL maintainer="hydazz"

# environment settings
ENV DEBIAN_FRONTEND=noninteractive \
    PREFIX_DIR=/usr/glibc-compat

RUN \
  apt-get update && \
  apt-get install -y \
    bison \
    build-essential \
    gawk \
    gettext \
    openssl \
    python3 \
    texinfo \
    wget

COPY root/ /

ENTRYPOINT ["/builder"]
