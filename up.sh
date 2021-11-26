#!/bin/bash
# 简易启动脚本
# 1. 生成组织和用户的证书
# 2. 生成系统通道的创世区块(映射到了排序节点)
# 3. 生成app通道的交易channel.tx
# 4. 生成锚节点更新交易 Org1MSPanchors.tx Org2MSPanchors.tx
# 5. 启动节点


set -euo pipefail
# 设置好二进制工具环境变量 export PATH=<path to download location>/bin:$PATH
export FABRIC_CFG_PATH=./config
###################################
# 创建加密材料
###################################
function rmFiles(){
	rm -rf ./organizations/crypto
	# rm -rf ./system-genesis-block
	# rm -rf ./channel-artifacts
}
rmFiles
set -e

if [ ! -f "./organizations/crypto-config.yaml" ]
then
    echo "organizations/crypto-config.yaml not found."
	exit 1
fi

which cryptogen 1>/dev/null
if [ "$?" == 0 ]; then
    echo "create ./organizations/crypto..."
    cryptogen generate --config=./organizations/crypto-config.yaml --output ./organizations/crypto
else
    echo "can't find cryptogen, install first."
	exit 1 
fi

# # 创建系统通道的创世区块和自定义通道
# # 环境变量 /指定-configPath(configtx.yaml路径)
# export FABRIC_CFG_PATH=${PWD}/config/
# DIRECTORY="./system-genesis-block"
# mkdir -p $DIRECTORY

# which configtxgen 1>/dev/null
# if [ "$?" == 0 ]; then
#     echo "create $DIRECTORY..." 
#     configtxgen -profile TwoOrgsOrdererGenesis -outputBlock $DIRECTORY/genesis.block -channelID system-channel
# else
#     echo "can't find configtxgen, install first." 
# 	exit 1
# fi

# DIRECTORY="./channel-artifacts" # 创建通道的交易
# : ${channelName:="myChannel"}
# mkdir -p $DIRECTORY
# echo "create $DIRECTORY..."
# configtxgen -profile TwoOrgsChannel -outputCreateChannelTx $DIRECTORY/channel.tx -channelID ${channelName}


# # 锚节点更新交易创建(默认好像会指定)
# configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $DIRECTORY/Org1MSPanchors.tx -channelID ${channelName} -asOrg Org1MSP
# configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate $DIRECTORY/Org2MSPanchors.tx -channelID ${channelName} -asOrg Org2MSP


#################################
# Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

DOCKER_SOCK=$DOCKER_SOCK docker-compose -f docker-compose.yaml up -d 2>&1
docker ps


echo -e "\n=================================================================\n"
echo 'create_channel [channelName=mychannel] and update anchorPeer......'
./utils/createChannel.sh


