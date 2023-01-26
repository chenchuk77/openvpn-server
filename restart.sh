#!/bin/bash -e


# ./restart.sh - will start web-server and openvpn-server
# ./restart.sh dev - will start a sleeping container, start manually by invoke ./entrypoint.sh

if [[ "$1" = "dev" ]]; then

  echo "running in dev mode: rebuilds, restart and login to a new dev tunnelx:0.0.1 container ..."
  # removing old tunnelx container
  docker stop tunnelx > /dev/null 2>&1 || true
  docker rm tunnelx   > /dev/null 2>&1 || true
  ./rebuild.sh
  OVERRIDE_CMD="/bin/sleep 1000h"
  docker run -d --rm \
    --name tunnelx --privileged \
    -p 8888:8888 -p 1194:1194/udp \
       tunnelx:0.0.1 ${OVERRIDE_CMD}
  # login
  docker exec -ti tunnelx /bin/bash
else
  echo "starting a new tunnelx:0.0.1 on localhost:8888 ..."
  # removing old tunnelx container
  docker stop tunnelx > /dev/null 2>&1 || true
  docker rm tunnelx   > /dev/null 2>&1 || true
  docker run -d --rm \
    --name tunnelx --privileged \
    -p 8888:8888 -p 1194:1194/udp \
       tunnelx:0.0.1
  echo "download client config at http://$(curl -s -4 ifconfig.io):8888/client.conf"
  echo "for linux openvpn client, save this as /etc/openvpn/client.conf"
fi
#
#
#
#echo "starting a new tunnelx:0.0.1 on localhost:8888 ..."
#docker run -d --rm \
#  --name tunnelx \
#  --privileged \
#  -p 8888:8888 \
#  -p 1194:1194/udp \
#     tunnelx:0.0.1 ${OVERRIDE_CMD}
##  -e PUBLIC_IP=$(curl -4 ifconfig.io)
#
#echo "download client config at http://$(curl -s -4 ifconfig.io):8888/client.conf"
#[[ "$1" = "dev" ]] && docker exec -ti tunnelx /bin/bash
