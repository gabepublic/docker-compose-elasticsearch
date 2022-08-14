#!/bin/bash

NAMESPACE="gabepublic"
IMG_NAME="sffoodtruck-site-flask"

BUILD_VER=0.1.0
PLATFORM="linux-amd64"

docker run -d --net foodtrucks-net -p 5000:5000 --name foodtrucks-web $NAMESPACE/$IMG_NAME:$BUILD_VER-$PLATFORM