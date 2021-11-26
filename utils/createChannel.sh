#!/bin/bash

set -euo pipefail
export FABRIC_CFG_PATH=./config
DIRECTORY="./channel-artifacts" # 创建通道的交易
: ${channelName:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}

mkdir -p $DIRECTORY
echo "create $DIRECTORY/genesis_block.pb..."
# 通道名称必须全部小写，长度小于 250 个字符并与正则表达式匹配[a-z][a-z0-9.-]*
configtxgen -profile TwoOrgsApplicationGenesis -outputBlock $DIRECTORY/genesis_block.pb -channelID ${channelName}
# 锚节点更新交易创建(默认好像会指定)
configtxgen -profile TwoOrgsApplicationGenesis -outputAnchorPeersUpdate $DIRECTORY/Org1MSPanchors.tx -channelID ${channelName} -asOrg Org1MSP
configtxgen -profile TwoOrgsApplicationGenesis -outputAnchorPeersUpdate $DIRECTORY/Org2MSPanchors.tx -channelID ${channelName} -asOrg Org2MSP


# 将多个排序节点添加到通道（至少达到多数才能运行）
export OSN_TLS_CA_ROOT_CERT=./organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/tls/ca.crt
export ADMIN_TLS_SIGN_CERT=./organizations/crypto/ordererOrganizations/test.com/users/Admin@test.com/tls/client.crt
export ADMIN_TLS_PRIVATE_KEY=./organizations/crypto/ordererOrganizations/test.com/users/Admin@test.com/tls/client.key

# 由于osnadmin CLI和 orderer之间的连接需要双向TLS，因此您需要在每个命令上传递--client-cert和--client-key参数
rc=1
COUNTER=1
while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
	sleep $DELAY
	{ set +e; } 2>/dev/null
	osnadmin channel join \
	--channelID ${channelName}  --config-block $DIRECTORY/genesis_block.pb \
	-o localhost:7053 --ca-file $OSN_TLS_CA_ROOT_CERT \
	--client-cert $ADMIN_TLS_SIGN_CERT \
	--client-key $ADMIN_TLS_PRIVATE_KEY
	rc=$?
	{ set -e; } 2>/dev/null
done
if [[ $rc != 0 ]]; then
echo 'Channel creation failed'
exit 1
fi

# # # 查看信息
# osnadmin channel list \
# --channelID ${channelName} -o localhost:7053 \
# --ca-file $OSN_TLS_CA_ROOT_CERT \
# --client-cert $ADMIN_TLS_SIGN_CERT \
# --client-key $ADMIN_TLS_PRIVATE_KEY



########################################################
# 将多个节点加入到通道，并配置锚节点
########################################################
########## org1 ############
# 设置环境变量，peer客户端使用 peer使用的工作目录好像是CONFIG_CFG_PATH
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$(pwd)/organizations/crypto/peerOrganizations/org1.test.com/peers/peer0.org1.test.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$(pwd)/organizations/crypto/peerOrganizations/org1.test.com/users/Admin@org1.test.com/msp
export CORE_PEER_ADDRESS=localhost:7051    #peer0.org1.test.com:7051
# 加入通道
peer channel join -b $DIRECTORY/genesis_block.pb
# # 锚节点更新
# peer channel update -o localhost:7050 \
# -c ${channelName} -f $DIRECTORY/Org1MSPanchors.tx \
# --tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem

########## org2 ############
# 各节点都要加入通道
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$(pwd)/organizations/crypto/peerOrganizations/org2.test.com/peers/peer0.org2.test.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$(pwd)/organizations/crypto/peerOrganizations/org2.test.com/users/Admin@org2.test.com/msp
export CORE_PEER_ADDRESS=localhost:9051    #peer0.org2.test.com:9051

 # 加入
peer channel join -b $DIRECTORY/genesis_block.pb
# # 锚节点更新
# peer channel update -o localhost:7050 \
# -c ${channelName} -f $DIRECTORY/Org2MSPanchors.tx \
# --tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem


#### 说明：
# 指定了锚节点，不用更新，如果更新需要重新**创建更新交易**---签名---提交
echo "\nTwoOrgsApplication channel is created! done!\n"