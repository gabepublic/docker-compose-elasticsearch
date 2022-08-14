#!/bin/bash

echo "Stop and remove foodtrucks-web..."
docker stop foodtrucks-web
docker rm foodtrucks-web

echo "Stop and remove es..."
docker stop es
docker rm es

echo "Remove foodtrucks-net..."
docker network rm foodtrucks-net
