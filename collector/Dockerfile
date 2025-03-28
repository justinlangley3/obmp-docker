# Collector: openbmp/collector
#
#  Copyright (c) 2021-2022 Cisco Systems, Inc. and others.  All rights reserved.
#
# Author: Tim Evens <tim@openbmp.org>
#
# BUILD:
#
#   Docker context does not support multiple paths or mounting volumes for builds.
#   In effort to build the container from local git clones, we dynamically build a context
#
#   Clone the obmp-collector and obmp-docker repos into the same directory.
#   Change directories to obmp-docker/collector and run the below from that
#   directory.
#
# Use buildkit - either via export DOCKER_BUILDKIT=1 or by using buildx cli
#
#   Example docker build:
#     tar -c -C ../../ ./obmp-collector ./obmp-docker/collector \
#           | docker buildx build --platform linux/amd64 --progress=plain \
#                 --build-arg VERSION=2.2.3 \
#                 -f obmp-docker/collector/Dockerfile -t openbmp/collector:2.2.3 -
#

#------------------------------------------------------------
# Build Stage
#------------------------------------------------------------
FROM alpine:3.20 AS build

# Copy source files
COPY obmp-collector/ /ws
WORKDIR /ws

# Install dependencies
RUN apk update && \
    apk add --no-cache \
      bash binutils cmake make \
      git gcc g++ musl libstdc++ \
      boost-dev cyrus-sasl-dev \
      librdkafka-dev lz4-dev \
      openssl-dev yaml-cpp-dev \
      zlib-dev zstd-dev

# Build and install
RUN rm -rf build && mkdir build && cd build && \
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr \
      ../ \
    && make \
    && make install

# Clean up unnecessary packages and caches
RUN apk del gcc g++ cmake make git openssl-dev boost-dev cyrus-sasl-dev librdkafka-dev yaml-cpp-dev zlib-dev zstd-dev && \
    rm -rf /var/cache/apk/* /tmp/*

#------------------------------------------------------------
# Final Stage
#------------------------------------------------------------
FROM alpine:3.20

# Install runtime dependencies
RUN apk update && \
    apk add --no-cache \
      bash iproute2 cyrus-sasl \
      libgcc librdkafka libstdc++ \
      openssl yaml-cpp zlib && \
    # Clean apk cache
    rm -rf /var/cache/apk/*

RUN mkdir -p /usr/etc/openbmp /usr/local/bin

# Copy necessary files from the build stage
COPY --from=build /usr/bin/openbmpd /usr/local/bin/
COPY --from=build /usr/etc/openbmp/openbmpd.conf /usr/etc/openbmp/openbmpd.conf

# Set up versioning and default configurations
ARG VERSION=0
RUN touch /usr/local/version-${VERSION} && \
    mkdir -p /etc/default && \
    touch /etc/default/openbmpd && \
    chmod 644 /etc/default/openbmpd

# Add the run script
ADD --chmod=755 obmp-docker/collector/scripts/run /usr/local/bin

# Define configuration volume
VOLUME ["/config"]

WORKDIR /tmp

CMD ["/usr/local/bin/run"]

# Expose required ports
EXPOSE 5000
