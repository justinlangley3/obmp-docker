#!/bin/bash

set -e
set -o pipefail

# Defaults
export OBMP_DATA_ROOT=/opt/openbmp
GRAFANA_REPO=https://github.com/OpenBMP/obmp-grafana.git
SKIP_CLEANUP=false
FORCE_RECREATE=false

echo_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --skip-cleanup)
      SKIP_CLEANUP=true
      ;;
    --data-root)
      shift
      OBMP_DATA_ROOT="$1"
      ;;
    --force-recreate)
      FORCE_RECREATE=true
      ;;
    --help)
      echo "Usage: $0 [--skip-cleanup] [--data-root <path>] [--force-recreate]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
  shift
done

# OpenBMP Volumes
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

# find existing volumes
EXISTING_VOLUMES=()
for volume in "${VOLUMES[@]}"; do
  if docker volume inspect "$volume" &>/dev/null; then
    EXISTING_VOLUMES+=("$volume")
  fi
done

if [ ${#EXISTING_VOLUMES[@]} -gt 0 ] && [ "$FORCE_RECREATE" = false ]; then
  echo_log "Volumes already exist!!
Note: Using '--force-recreate' will destroy and rebuild the volumes (with data loss)
$(printf "%s\n" "${EXISTING_VOLUMES[@]}")"
  exit 1
fi

if [ "$FORCE_RECREATE" = true ] && [ ${#EXISTING_VOLUMES[@]} -gt 0 ]; then
  echo_log "Forcing recreation of existing volumes: $(printf "%s " "${EXISTING_VOLUMES[@]}")"
  for volume in "${EXISTING_VOLUMES[@]}"; do
    echo_log "Removing existing volume: $volume"
    docker volume rm "$volume"
  done
fi

echo_log "Creating Docker volumes..."
for volume in "${VOLUMES[@]}"; do
  if ! docker volume inspect "$volume" &>/dev/null; then
    echo_log "Creating volume: $volume"
    docker volume create "$volume"
  fi
done

if [ -d "obmp-grafana" ]; then
  if [ "$FORCE_RECREATE" = true ]; then
    echo_log "Forcing recreation of Grafana repository..."
    rm -rf obmp-grafana
  else
    echo_log "Grafana repository already exists. Skipping clone."
  fi
fi

echo_log "Cloning Grafana repository..."
git clone "$GRAFANA_REPO" obmp-grafana

echo_log "Setting up Grafana directories..."
mkdir -p ${OBMP_DATA_ROOT}/grafana/provisioning/{dashboards,datasources}

cp -r obmp-grafana/dashboards ${OBMP_DATA_ROOT}/grafana/
cp -r obmp-grafana/provisioning/dashboards ${OBMP_DATA_ROOT}/grafana/provisioning/
cp -r obmp-grafana/provisioning/datasources ${OBMP_DATA_ROOT}/grafana/provisioning/

echo_log "Patching PostgreSQL datasource version..."
sed -i 's/postgresVersion: 1200/postgresVersion: 1400/' \
  ${OBMP_DATA_ROOT}/grafana/provisioning/datasources/openbmp-ds.yml

echo_log "Copying provisioning files to Docker volumes..."
for src_dir in "dashboards" "provisioning/dashboards" "provisioning/datasources"; do
  dest_volume="obmp-grafana-${src_dir//\//-}"  # Convert slashes to dashes
  if docker volume inspect "$dest_volume" &>/dev/null; then
    echo_log "Copying $src_dir to $dest_volume..."
    docker run --rm -v ${OBMP_DATA_ROOT}/grafana/$src_dir:/src -v $dest_volume:/mnt busybox sh -c "
      if [ -n \"\$(ls -A /src 2>/dev/null)\" ]; then
        cp -r /src/* /mnt/
      else
        echo 'Warning: Source directory /src is empty. Skipping copy.'
      fi
    "
  else
    echo_log "Warning: Volume $dest_volume does not exist, skipping..."
  fi
done

echo_log "Setting permissions for volumes..."
for volume in "obmp-grafana-dashboards" "obmp-grafana-provisioning-dashboards" "obmp-grafana-provisioning-datasources"; do
  echo_log "Volume: ${volume}"
  docker run --rm -v "$volume":/mnt busybox sh -c "
    chown -R 472:0 /mnt &&
    find /mnt -type d -exec chmod 755 {} \; &&
    find /mnt -type f -exec chmod 644 {} \;
    find /mnt -exec ls -ld {} \; | awk '{print \$1, \$3, \$4, \$9}'
  "
done

if [ "$SKIP_CLEANUP" = false ]; then
  echo_log "Cleaning up temporary files..."
  docker image rm busybox || true
  rm -rf ./obmp-grafana ${OBMP_DATA_ROOT}
fi

echo_log "Existing Docker volumes:"
docker volume ls

echo_log "Setup complete. You can now run: docker-compose up -d"

