#!/bin/bash

function rmFiles() {
	rm -rf ./organizations/crypto
	# rm -rf ./channel-artifacts
}

# docker volume prune
function clearContainers() {
  echo "Removing remaining containers"
  docker rm -f $(docker ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  docker rm -f $(docker ps -aq --filter name='dev-peer*') 2>/dev/null || true
  docker stop logspout 2>/dev/null || true
  docker rm -f logspout 2>/dev/null || true
}

# 链码镜像
function removeUnwantedImages() {
  echo "Removing generated chaincode docker images"
  docker image rm -f $(docker images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

#######################################
SOCK="${DOCKER_HOST:-/var/run/docker.sock}" # null return
DOCKER_SOCK="${SOCK##unix://}"

DOCKER_SOCK=$DOCKER_SOCK docker-compose -f ./docker-compose.yaml  down 
clearContainers
docker volume prune -f # --filter label=service=hyperledger-fabric
removeUnwantedImages

rmFiles
