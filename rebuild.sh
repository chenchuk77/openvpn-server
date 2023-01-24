#!/bin/bash -e

#
# this script builds a env-status image
# from the current folder, and pushes the image upon success.
# make sure to bump the version when developing new features.

#VERSION=$(grep 'app_version' app/view3/view3.js | cut -d "=" -f2 | tr -d " ;'")
VERSION=0.0.1

#echo "building artifact01.nj.peer39.com:5000/ops/env-status:${VERSION} ..."
#sleep 2s

echo "building the current workspace ..."
docker build -t tunnelx:${VERSION} .

#docker build -t non-prod-deployment:${VERSION} .
#sleep 2s

#echo "tag and push image ..."
#docker tag env-status:${VERSION} artifact01.nj.peer39.com:5000/ops/env-status:${VERSION}
#docker push artifact01.nj.peer39.com:5000/ops/env-status:${VERSION}

#echo "done: artifact01.nj.peer39.com:5000/ops/env-status:${VERSION} released."

