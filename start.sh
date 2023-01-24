#!/bin/bash -e

echo "removing old tunnelx container ..."
docker stop tunnelx || true
docker rm tunnelx || true

echo "starting a new tunnelx:0.0.1 on localhost:8888 ..."
docker run -d --rm \
  --name tunnelx \
  --privileged \
  -p 1194:1194/udp \
     tunnelx:0.0.1
#  -e PUBLIC_IP=$(curl -4 ifconfig.io)


