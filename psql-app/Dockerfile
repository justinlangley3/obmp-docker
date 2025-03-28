# Use buildkit - either via export DOCKER_BUILDKIT=1 or by using buildx cli
#
# Example docker build:
# tar -c -C ../../ ./obmp-psql ./obmp-docker/psql-app ./obmp-java-api-message \
#     | docker buildx build --platform linux/amd64 --progress=plain \
#         --build-arg VERSION=2.2.2 \
#         -f obmp-docker/psql-app/Dockerfile -t openbmp/psql-app:2.2.2 -

# -----------------------------------------------
# Build Stage: Build the Java application
# ----------------------------------------------
FROM alpine:3.20 AS build

ARG VERSION=0.0.0

# Install build dependencies (Java JDK and Maven)
RUN apk update && apk add --no-cache \
    openjdk17-jdk maven

# Copy source code
COPY obmp-psql/ /ws
COPY obmp-java-api-message/ /tmp/obmp-java-api-message

WORKDIR /ws

# Build the Java application
RUN cd /tmp/obmp-java-api-message && mvn clean install && \
    cd /ws && mvn clean package

# Clean up build dependencies to keep image small
RUN apk del openjdk17-jdk maven && \
    rm -rf /var/cache/apk/* /root/.m2

# -----------------------------------------------
# Final Image: Install runtime dependencies
# -----------------------------------------------
FROM alpine:3.20

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    bash \
    cronie \
    curl \
    kafkacat \
    openjdk17-jre \
    py3-dnspython \
    py3-click \
    py3-ipaddr \
    py3-netaddr \
    py3-pip \
    py3-psycopg2 \
    py3-requests \
    py3-urllib3 \
    postgresql14-client \
    rsync \
    rsyslog \
    whois \
    unzip && \
    rm -rf /var/cache/apk/*

# Install additional Python dependencies
RUN pip3 install --break-system-packages pykafka

# Disable unneeded rsyslog module to save space
RUN sed -i '/module(load="imklog")/s/^/#/' /etc/rsyslog.conf

# Ensure cron and rsyslog directories exist
RUN mkdir -p /var/spool/cron/crontabs && chmod -R 600 /var/spool/cron/crontabs \
    && mkdir -p /var/log/ && touch /var/log/cron.log /var/log/syslog /var/log/openbmpd.log

# Copy built artifacts from the build stage
COPY --from=build /ws/target/obmp-psql-consumer-0.1.0-SNAPSHOT.jar /usr/local/openbmp/obmp-psql-consumer.jar
COPY --from=build /ws/database/ /usr/local/openbmp/database
COPY --from=build /ws/cron_scripts/gen-whois/*.py /usr/local/openbmp/
COPY --from=build /ws/cron_scripts/peeringdb/*.py /usr/local/openbmp/
COPY --from=build /ws/cron_scripts/rpki/*.py /usr/local/openbmp/
COPY --from=build /ws/scripts/geo-csv-to-psql.py /usr/local/openbmp/
COPY --from=build /ws/scripts/db-ip-import.sh /usr/local/openbmp/

# Add necessary scripts and binaries for runtime
ADD --chmod=755 obmp-docker/psql-app/scripts/start-services /usr/local/bin
COPY --chmod=755 obmp-docker/psql-app/upgrade /tmp/upgrade

# Define persistent data volumes
VOLUME ["/config"]

# Expose necessary ports
EXPOSE 9005

# Default command to start services
CMD ["/usr/local/bin/start-services"]
