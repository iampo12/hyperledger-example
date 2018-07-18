#!/bin/bash

docker-compose -f docker-compose.yml down
docker rm $(docker ps -a | grep 'dev' | awk '{print $1}')
docker rmi $(docker images dev-* -q)

