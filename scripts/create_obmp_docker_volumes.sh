#!/bin/bash

export OBMP_DATA_ROOT=/opt/openbmp

# OpenBMP Docker Volumes
VOLUMES=(
  obmp-config
  obmp-grafana-data
  obmp-grafana-dashboards
  obmp-grafana-provisioning-dashboards
  obmp-grafana-provisioning-datasources
  obmp-kafka-data
  obmp-psql-data
  obmp-psql-ts
  obmp-zk-data
  obmp-zk-logs
)

# remove existing volumes if they exist
for volume in "${VOLUMES[@]}"; do
  if docker volume inspect "$volume" &>/dev/null; then
    echo "Removing existing volume: $volume"
    docker volume rm "$volume"
  fi
  echo "Creating volume: $volume"
  docker volume create "$volume"
done

# clone Grafana provisioning repository
git clone https://github.com/OpenBMP/obmp-grafana.git

# setup work directory
mkdir -p ${OBMP_DATA_ROOT}/grafana
mkdir -p ${OBMP_DATA_ROOT}/grafana/provisioning/dashboards
mkdir -p ${OBMP_DATA_ROOT}/grafana/provisioning/datasources

# copy provisioning files to work directory
cp -r obmp-grafana/dashboards ${OBMP_DATA_ROOT}/grafana/
cp -r obmp-grafana/provisioning/dashboards ${OBMP_DATA_ROOT}/grafana/provisioning/
cp -r obmp-grafana/provisioning/datasources ${OBMP_DATA_ROOT}/grafana/provisioning/

# patch postgresql datasource version
sed -i 's/postgresVersion: 1200/postgresVersion: 1400/' ${OBMP_DATA_ROOT}/grafana/provisioning/datasources/openbmp-ds.yml

# prepare the Grafana volumes with a busybox image
docker run --rm -v ${OBMP_DATA_ROOT}/grafana/dashboards:/src -v obmp-grafana-dashboards:/mnt busybox sh -c "cp -r /src/* /mnt/"
docker run --rm -v ${OBMP_DATA_ROOT}/grafana/provisioning/dashboards:/src -v obmp-grafana-provisioning-dashboards:/mnt busybox sh -c "cp -r /src/* /mnt/"
docker run --rm -v ${OBMP_DATA_ROOT}/grafana/provisioning/datasources:/src -v obmp-grafana-provisioning-datasources:/mnt busybox sh -c "cp -r /src/* /mnt/"

# adjust ownership and permissions for directories and files
for volume in "obmp-grafana-dashboards" "obmp-grafana-provisioning-dashboards" "obmp-grafana-provisioning-datasources"; do
  echo "Setting ownership and permissions for volume: $volume"
  docker run --rm -v "$volume":/mnt busybox sh -c "
    chown -R 472:0 /mnt &&
    find /mnt -type d -exec chmod 755 {} \; &&
    find /mnt -type f -exec chmod 644 {} \;
  "
done

#echo "Verifying contents of volumes..."
#docker run --rm -v obmp-grafana-dashboards:/mnt busybox sh -c "ls -lR /mnt"
#docker run --rm -v obmp-grafana-provisioning-dashboards:/mnt busybox sh -c "ls -lR /mnt"
#docker run --rm -v obmp-grafana-provisioning-datasources:/mnt busybox sh -c "ls -lR /mnt"

# cleanup busybox image
docker image rm busybox

# cleanup work directories
rm -rf ./obmp-grafana ${OBMP_DATA_ROOT}

# display created volumes
echo "\nExisting Docker volumes:"
docker volume ls

echo "\nYou can now run: docker-compose up -d"


