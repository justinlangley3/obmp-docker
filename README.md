# OpenBMP docker files
Docker files for OpenBMP.

## (Prerequisite) Platform Docker Install

> Ignore this step if you already have a current docker install

> **NOTE**
> You should use the latest docker version, documented in this section.

Follow the instructions on https://docs.docker.com/get-docker/

### Optionally add a non-root user to run docker as
    usermod -aG docker ubuntu
    
    # Logout and log back so the group takes affect. 


### Optionally configure **/etc/default/docker** (e.g. for proxy config)

    export http_proxy="http://proxy:80/"
    export https_proxy="http://proxy:80/"
    export no_proxy="127.0.0.1,openbmp.org,/var/run/docker.sock"

Make sure you can run '**docker run hello-world**' successfully.


## OpenBMP Docker Files
Each docker file contains a readme file, see below:

* [Collector](collector/README.md)
* [PostgreSQL](postgres/README.md)
* [PSQL Consumer](psql-app/README.md)


## Using Docker Compose to run everything

### Install Docker Compose
You will need docker-compose.  You can install that via [Docker Compose](https://docs.docker.com/compose/install/)
instructions.  Docker compose will run everything, including handling restarts of containers. 

#### (1) Setup persistent volumes
Bind mounts mapped to world-writeable directories were used in the past. Besides posing a security risk, it was problematic for multi-user systems with service accounts already mapped to specific UIDs/GIDs.  
Volumes are a far better method of persisting the container data, and allows setting more sane permissions e.g. 0755 (directory), 0644 (file), and ownership by the container user.

Creating Docker Volumes  
A script is provided to automate this step, with Busybox used to load Grafana data into the respective volumes.  
_Note_: Using `--force-recreate` will destroy and rebuild existing volumes (with data loss).
```
./scripts/create_obmp_docker_volumes.sh --force-recreate
[2025-02-26 23:09:49] Forcing recreation of existing volumes: obmp-config obmp-grafana-data obmp-grafana-dashboards obmp-grafana-provisioning-dashboards obmp-grafana-provisioning-datasources obmp-kafka-data obmp-psql-data obmp-psql-ts obmp-zk-data obmp-zk-logs 
[2025-02-26 23:09:49] Removing existing volume: obmp-config
obmp-config
[2025-02-26 23:09:49] Removing existing volume: obmp-grafana-data
obmp-grafana-data
[2025-02-26 23:09:49] Removing existing volume: obmp-grafana-dashboards
obmp-grafana-dashboards
[2025-02-26 23:09:49] Removing existing volume: obmp-grafana-provisioning-dashboards
obmp-grafana-provisioning-dashboards
[2025-02-26 23:09:49] Removing existing volume: obmp-grafana-provisioning-datasources
obmp-grafana-provisioning-datasources
[2025-02-26 23:09:49] Removing existing volume: obmp-kafka-data
obmp-kafka-data
[2025-02-26 23:09:49] Removing existing volume: obmp-psql-data
obmp-psql-data
[2025-02-26 23:09:49] Removing existing volume: obmp-psql-ts
obmp-psql-ts
[2025-02-26 23:09:49] Removing existing volume: obmp-zk-data
obmp-zk-data
[2025-02-26 23:09:49] Removing existing volume: obmp-zk-logs
obmp-zk-logs
[2025-02-26 23:09:49] Creating Docker volumes...
[2025-02-26 23:09:49] Creating volume: obmp-config
obmp-config
[2025-02-26 23:09:49] Creating volume: obmp-grafana-data
obmp-grafana-data
[2025-02-26 23:09:49] Creating volume: obmp-grafana-dashboards
obmp-grafana-dashboards
[2025-02-26 23:09:49] Creating volume: obmp-grafana-provisioning-dashboards
obmp-grafana-provisioning-dashboards
[2025-02-26 23:09:49] Creating volume: obmp-grafana-provisioning-datasources
obmp-grafana-provisioning-datasources
[2025-02-26 23:09:49] Creating volume: obmp-kafka-data
obmp-kafka-data
[2025-02-26 23:09:49] Creating volume: obmp-psql-data
obmp-psql-data
[2025-02-26 23:09:49] Creating volume: obmp-psql-ts
obmp-psql-ts
[2025-02-26 23:09:49] Creating volume: obmp-zk-data
obmp-zk-data
[2025-02-26 23:09:49] Creating volume: obmp-zk-logs
obmp-zk-logs
[2025-02-26 23:09:49] Cloning Grafana repository...
Cloning into 'obmp-grafana'...
remote: Enumerating objects: 307, done.
remote: Counting objects: 100% (307/307), done.
remote: Compressing objects: 100% (150/150), done.
remote: Total 307 (delta 170), reused 274 (delta 138), pack-reused 0 (from 0)
Receiving objects: 100% (307/307), 120.22 KiB | 1.33 MiB/s, done.
Resolving deltas: 100% (170/170), done.
[2025-02-26 23:09:50] Setting up Grafana directories...
[2025-02-26 23:09:50] Patching PostgreSQL datasource version...
[2025-02-26 23:09:50] Copying provisioning files to Docker volumes...
[2025-02-26 23:09:50] Copying dashboards to obmp-grafana-dashboards...
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
9c0abc9c5bd3: Pull complete 
Digest: sha256:498a000f370d8c37927118ed80afe8adc38d1edcbfc071627d17b25c88efcab0
Status: Downloaded newer image for busybox:latest
[2025-02-26 23:09:52] Copying provisioning/dashboards to obmp-grafana-provisioning-dashboards...
[2025-02-26 23:09:53] Copying provisioning/datasources to obmp-grafana-provisioning-datasources...
[2025-02-26 23:09:53] Setting permissions for volumes...
[2025-02-26 23:09:53] Volume: obmp-grafana-dashboards
drwxr-xr-x 472 root /mnt
drwxr-xr-x 472 root /mnt/General
-rw-r--r-- 472 root /mnt/General/OBMP-Home.json
drwxr-xr-x 472 root /mnt/obmp
drwxr-xr-x 472 root /mnt/obmp/Base-1001
-rw-r--r-- 472 root /mnt/obmp/Base-1001/inventory.json
-rw-r--r-- 472 root /mnt/obmp/Base-1001/asn_view.json
-rw-r--r-- 472 root /mnt/obmp/Base-1001/looking_glass.json
drwxr-xr-x 472 root /mnt/obmp/L3VPN-1005
-rw-r--r-- 472 root /mnt/obmp/L3VPN-1005/l3vpn_rib_browser.json
-rw-r--r-- 472 root /mnt/obmp/L3VPN-1005/l3vpn_looking_glass.json
-rw-r--r-- 472 root /mnt/obmp/L3VPN-1005/l3vpn_prefix_hist.json
drwxr-xr-x 472 root /mnt/obmp/LinkState-1004
-rw-r--r-- 472 root /mnt/obmp/LinkState-1004/ls_history.json
-rw-r--r-- 472 root /mnt/obmp/LinkState-1004/ls_prefixes.json
-rw-r--r-- 472 root /mnt/obmp/LinkState-1004/ls_topo.json
-rw-r--r-- 472 root /mnt/obmp/LinkState-1004/ls_links.json
-rw-r--r-- 472 root /mnt/obmp/LinkState-1004/ls_nodes.json
drwxr-xr-x 472 root /mnt/obmp/Tops-1003
-rw-r--r-- 472 root /mnt/obmp/Tops-1003/top_l3vpn_prefixes.json
-rw-r--r-- 472 root /mnt/obmp/Tops-1003/top_prefixes.json
drwxr-xr-x 472 root /mnt/obmp/History-1002
-rw-r--r-- 472 root /mnt/obmp/History-1002/prefix_hist_asn.json
-rw-r--r-- 472 root /mnt/obmp/History-1002/prefix_hist_community.json
-rw-r--r-- 472 root /mnt/obmp/History-1002/prefix_history.json
[2025-02-26 23:09:54] Volume: obmp-grafana-provisioning-dashboards
drwxr-xr-x 472 root /mnt
-rw-r--r-- 472 root /mnt/openbmp-dashboards.yml
[2025-02-26 23:09:55] Volume: obmp-grafana-provisioning-datasources
drwxr-xr-x 472 root /mnt
-rw-r--r-- 472 root /mnt/openbmp-ds.yml
[2025-02-26 23:09:55] Cleaning up temporary files...
Untagged: busybox:latest
Untagged: busybox@sha256:498a000f370d8c37927118ed80afe8adc38d1edcbfc071627d17b25c88efcab0
Deleted: sha256:31311c5853a22c04d692f6581b4faa25771d915c1ba056c74e5ec82606eefdfa
Deleted: sha256:59654b79daad74c77dc2e28502ca577ba8ce73276720002234a23fc60ee92692
[2025-02-26 23:09:55] Existing Docker volumes:
DRIVER    VOLUME NAME
local     obmp-config
local     obmp-grafana-dashboards
local     obmp-grafana-data
local     obmp-grafana-provisioning-dashboards
local     obmp-grafana-provisioning-datasources
local     obmp-kafka-data
local     obmp-psql-data
local     obmp-psql-ts
local     obmp-zk-data
local     obmp-zk-logs
[2025-02-26 23:09:55] Setup complete. You can now run: docker-compose up -d
```

#### (2) Start OpenBMP services
```
export OBMP_PSQL_DATABASE=openbmp
export OBMP_PSQL_USERNAME=changeme
export OBMP_PSQL_PASSWORD=changeme
export OBMP_GRAFANA_PASSWORD=changeme
docker compose up -d
```

