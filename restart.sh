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
    -p 80:80 -p 443:443 -p 1194:1194/udp \
       tunnelx:0.0.1 ${OVERRIDE_CMD}
  # login
  docker exec -ti tunnelx /bin/bash
else
  echo "starting a new tunnelx:0.0.1 on localhost:443 ..."
  # removing old tunnelx container
  docker stop tunnelx > /dev/null 2>&1 || true
  docker rm tunnelx   > /dev/null 2>&1 || true
  docker run -d --rm \
    --name tunnelx --privileged \
    -p 80:80 -p 443:443 -p 1194:1194/udp \
       tunnelx:0.0.1
  echo "tunnelx daemon started ..."
  echo "u can download client config here:"
  echo ""
  for name in $(cat userlist); do
    echo "  https://$(curl -s -4 ifconfig.io)/conf/${name}"
  done
  echo "open this file with openvpn-connect."
  echo ""

fi
