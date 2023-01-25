#!/bin/bash -e


# ./start.sh - will start web-server and openvpn-server
# ./start.sh dev - will start a sleeping container, start manually by invoke ./entrypoint.sh

OVERRIDE_CMD=""

if [[ "$1" = "dev" ]]; then
  OVERRIDE_CMD="/bin/sleep 1000h"
  ./rebuild.sh
fi


echo "removing old tunnelx container ..."
docker stop tunnelx || true
docker rm tunnelx || true

echo "starting a new tunnelx:0.0.1 on localhost:8888 ..."
docker run -d --rm \
  --name tunnelx \
  --privileged \
  -p 8888:8888 \
  -p 1194:1194/udp \
     tunnelx:0.0.1 ${OVERRIDE_CMD}
#  -e PUBLIC_IP=$(curl -4 ifconfig.io)

echo "download client config at http://$(curl -4 ifconfig.io):8888/client.conf"
[[ "$1" = "dev" ]] && docker exec -ti tunnelx /bin/bash
