# Development build container: openbmp/dev-image
#
#  Copyright (c) 2021-2022 Cisco Systems, Inc. and others.  All rights reserved.
#
#  Container used to build the OpenBMP components
#
# Author: Tim Evens <tim@openbmp.org>
#
# BUILD: docker buildx build  --platform linux/amd64 --progress=plain -t openbmp/dev-image:latest .

# --------------------------------------------------------
# Base Development Image: Install Development Tools and Libraries
# --------------------------------------------------------
FROM alpine:3.20 AS dev-image

# Install development dependencies (use minimal packages for dev environment)
RUN apk update && apk add --no-cache \
    bash \
    git \
    cmake \
    make \
    gcc \
    g++ \
    musl-dev \
    libstdc++ \
    boost-dev \
    cyrus-sasl-dev \
    librdkafka-dev \
    lz4-dev \
    openssl-dev \
    yaml-cpp-dev \
    zlib-dev \
    zstd-dev \
    py3-pip \
    py3-dnspython \
    py3-click \
    py3-ipaddr \
    py3-netaddr \
    py3-psycopg2 \
    py3-requests \
    py3-urllib3 \
    postgresql14-client \
    rsyslog \
    curl \
    kafkacat \
    python3 \
    openjdk17-jdk openjdk17-jre