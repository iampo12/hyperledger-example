#!/bin/bash

docker-compose -f docker-compose.yml down
docker rmi $(docker images dev-* -q)

docker-compose -f docker-compose.yml up -d

# should be set CORE_PEER_MSPCONFIGPATH in docker-compose ? -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/devnetwork/users/Admin@iampo12.me/msp"
docker exec peer0.iampo12.me peer channel create -o orderer.abc.me:7050 -c mychannel -f /etc/hyperledger/devnetwork/configtx/channel.tx
docker exec peer0.iampo12.me peer channel join -b mychannel.block

docker exec cli peer chaincode install -n sacc -p github.com/sacc -v 1.0
docker exec cli peer chaincode instantiate -n sacc -v 1.0 -c '{"Args":["a","10"]}' -C mychannel
# docker exec cli peer chaincode query -n sacc -v 1.0 -c '{"Args":["query","a"]}' -C mychannel
# docker exec cli peer chaincode invoke -n sacc -v 1.0 -c '{"Args":["set","a","10"]}' -C mychannel
