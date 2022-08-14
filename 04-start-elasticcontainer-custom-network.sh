#!/bin/bash

BUILD_VER=6.3.2

docker run -d --net foodtrucks-net -p 9200:9200 -p 9300:9300 --name es -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:$BUILD_VER