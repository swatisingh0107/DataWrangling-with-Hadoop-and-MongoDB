#!/usr/bin/env sh
#This script downloads HDF sandbox along with their proxy docker container

#To troubleshoot cgroup mount issue in docker 18.03
docker-machine ssh default "sudo mkdir /sys/fs/cgroup/systemd"
docker-machine ssh default "sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd"

set -x

# CAN edit these values
registry="hortonworks"
name="sandbox-hdf"
version="3.1.1"
flavor="hdf"
proxyName="sandbox-proxy"
proxyVersion="1.0"

# NO EDITS BEYOND THIS LINE

# create necessary folders for nginx and copy over our rule generation script there
echo $flavor > sandbox-flavor
mkdir -p sandbox/proxy/conf.d
mkdir -p sandbox/proxy/conf.stream.d

# pull and tag the sandbox and the proxy container
docker pull "$registry/$name:$version"
docker pull "$registry/$proxyName:$proxyVersion"


# start the docker container and proxy
if [ "$flavor" == "hdf" ]; then
 hostname="sandbox-hdf.hortonworks.com"
elif [ "$flavor" == "hdp" ]; then
 hostname="sandbox-hdp.hortonworks.com"
fi

version=$(docker images | grep hortonworks/$name  | awk '{print $2}');

# Create cda docker network
docker network create cda 2>/dev/null

# Deploy the sandbox into the cda docker network
docker run --privileged --name $name -h $hostname --network=cda --network-alias=$hostname -d "$registry/$name:$version"

echo "Remove existing postgres run files. Please wait..."
sleep 2
docker exec -t "$name" sh -c "rm -rf /var/run/postgresql/*; systemctl restart postgresql;"

# Deploy the proxy container.
# sed 's/sandbox-hdf-standalone-cda-ready/sandbox-hdf/g' assets/generate-proxy-deploy-script.sh > assets/generate-proxy-deploy-script.sh.new
# mv -f assets/generate-proxy-deploy-script.sh.new assets/generate-proxy-deploy-script.sh
# chmod +x assets/generate-proxy-deploy-script.sh
# assets/generate-proxy-deploy-script.sh 2>/dev/null
#check to see if it's windows
if uname | grep MINGW; then
 sed -i -e 's/\( \/[a-z]\)/\U\1:/g' sandbox/proxy/proxy-deploy.sh
fi
chmod +x sandbox/proxy/proxy-deploy.sh 2>/dev/null
sandbox/proxy/proxy-deploy.sh
