#!/bin/bash

echo "##########################################################"
echo "#####      Generate config for crypto-config     #########"
echo "##########################################################"

json="$(../node_modules/js-yaml/bin/js-yaml.js config-file.yml)"
ordererName="$(../node_modules/node-jq/bin/jq -r '.OrdererOrgs[0].Name' <<< "$json")"
ordererDomain="$(../node_modules/node-jq/bin/jq -r '.OrdererOrgs[0].Domain' <<< "$json")"
peers="$(../node_modules/node-jq/bin/jq '.PeerOrgs' <<< "$json")"
peerNames=($(../node_modules/node-jq/bin/jq -r '@sh "peerName=\(.[].Name)"' <<< "$peers"))
peerDomains=($(../node_modules/node-jq/bin/jq -r '@sh "peerDomain=\(.[].Domain)"' <<< "$peers"))
# TODO: orderer type solo, kafka

rm -f crypto-config.yml docker-compose.yml

( echo "cat <<EOF >crypto-config.yml"; cat template/orderer-template.yml; )>temp.yml
. temp.yml
rm -f temp.yml
echo "Generate Orderer"

for i in "${!peerNames[@]}"; 
do
  eval "${peerNames[$i]}"
  eval "${peerDomains[$i]}"
  ( echo "cat <<EOF >>crypto-config.yml"; cat template/peer-template.yml; )>temp.yml
  . temp.yml
  rm -f temp.yml

  ( echo "cat <<EOF >>peer-configtx-temp.yml"; cat template/peer-configtx-template.yml; )>temp.yml
  . temp.yml
  rm -f temp.yml

  echo "Generate Peer ${peerNames[$i]}"
done

echo "##########################################################"
echo "##### Generate certificates using cryptogen tool #########"
echo "##########################################################"

if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
fi

function generateConfigTx () {
    # sed on MacOSX does not support -i flag with a null extension. We will use
    # 't' for our back-up's extension and delete it at the end of the function
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    ORG_LIST_PEER=("$(cat peer-configtx-temp.yml)")

    cp template/configtx-template.yml configtx-temp.yml
    sed $OPTS "s/ORDERER_DOMAIN/${ordererDomain}/g" configtx-temp.yml
    # If MacOSX, remove the temporary backup of the docker-compose file
    if [ "$ARCH" == "Darwin" ]; then
        rm configtx-temp.ymlt
    fi

    ( echo "cat <<EOF >configtx.yml"; cat configtx-temp.yml; )>temp.yml
    . temp.yml
    rm -f temp.yml configtx-temp.yml peer-configtx-temp.yml
}

function replacePrivateKey () {
    # sed on MacOSX does not support -i flag with a null extension. We will use
    # 't' for our back-up's extension and delete it at the end of the function
    ARCH=`uname -s | grep Darwin`
    if [ "$ARCH" == "Darwin" ]; then
        OPTS="-it"
    else
        OPTS="-i"
    fi

    # Copy the template to the file that will be modified to add the private key
    # cp template/docker-compose-template.yml docker-compose.yml

    for i in "${!peerNames[@]}"; 
    do
        eval "${peerNames[$i]}"
        eval "${peerDomains[$i]}"

        CURRENT_DIR=`pwd`
        cd crypto-config/peerOrganizations/${peerDomain}/ca/
        CA_PRIVATE_KEY=$(ls *_sk)

        cd $CURRENT_DIR

        ( echo "cat <<EOF >>peer-compose-temp.yml"; cat template/peer-compose-template.yml; )>temp.yml
        . temp.yml
        rm -f temp.yml

        # CURRENT_DIR=`pwd`
        # cd crypto-config/peerOrganizations/${peerDomains[$i]}/ca/
        # PRIV_KEY=$(ls *_sk)
        # cd "$CURRENT_DIR"
        # sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
        # # If MacOSX, remove the temporary backup of the docker-compose file
        # if [ "$ARCH" == "Darwin" ]; then
        #     rm docker-compose.ymlt
        # fi
    done
    PEER_COMPOSE=("$(cat peer-compose-temp.yml)")
    ( echo "cat <<EOF >docker-compose.yml"; cat template/docker-compose-template.yml; )>temp.yml
    . temp.yml
    rm -f temp.yml peer-compose-temp.yml

    # # The next steps will replace the template's contents with the
    # # actual values of the private key file names for the two CAs.
    # CURRENT_DIR=`pwd`
    # cd crypto-config/peerOrganizations/iampo12.me/ca/
    # PRIV_KEY=$(ls *_sk)
    # cd "$CURRENT_DIR"
    # sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml
    # # If MacOSX, remove the temporary backup of the docker-compose file
    # if [ "$ARCH" == "Darwin" ]; then
    #     rm docker-compose.ymlt
    # fi
}

cryptogen generate --config=./crypto-config.yml

generateConfigTx

configtxgen -profile OneOrdererGenesis -outputBlock ./config/genesis.block

configtxgen -profile OneOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID mychannel

configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./config/PorMSPanchors.tx -channelID mychannel -asOrg PorMSP

replacePrivateKey