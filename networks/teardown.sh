#!/bin/bash

docker-compose -f docker-compose.yml down
docker rmi $(docker images dev-* -q)

