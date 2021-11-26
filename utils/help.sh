

# 可能用到的命令

# 进入cli节点操作
docker exec -it cli bash
#################################

# 创建通道  https://hyperledger-fabric.readthedocs.io/zh_CN/latest/create_channel/create_channel.html
### 需要core config 初始化
### $FABRIC_CFG_PATH=/Users/xiao/docker-project/fabric-deploy/config/
### ip地址，单机测试使用localhost
# peer channel create -o orderer.test.com:7050 \
# -c myChannel -f $(PWD)/channel-artifacts/channel.tx \
# --tls --cafile $(PWD)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem


########## org1 ############
# 设置环境变量，peer客户端使用
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$(pwd)/organizations/crypto/peerOrganizations/org1.test.com/peers/peer0.org1.test.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$(pwd)/organizations/crypto/peerOrganizations/org1.test.com/users/Admin@org1.test.com/msp
export CORE_PEER_ADDRESS=localhost:7051
# 加入通道
peer channel join -b myChannel.block
# # 锚节点指定
# peer channel update -o orderer.test.com:7050 \
# -c myChannel -f ./channel-artifacts/Org1MSPanchors.tx \
# --tls --cafile ./organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem


########## org2 ############
# 各节点都要加入通道
export CORE_PEER_LOCALMSPID="Org2MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=$(pwd)/organizations/crypto/peerOrganizations/org2.test.com/peers/peer0.org2.test.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$(pwd)/organizations/crypto/peerOrganizations/org2.test.com/users/Admin@org2.test.com/msp
export CORE_PEER_ADDRESS=localhost:9051

 # 加入
peer channel join -b myChannel.block
# # 锚节点指定
# peer channel update -o orderer.test.com:7050 \
# -c myChannel -f ./channel-artifacts/Org2MSPanchors.tx \
# --tls --cafile ./organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem

# 使用up.sh两个节点都加入通道, 直接测试链码
# 注意 生成证书的cryto-config.yaml 对tsl证书的SANS必须加上localhost,实际地址，否则会链接失败
###---------------------------------------------------------------
###---------------------------------------------------------------
###---------------------------------------------------------------

# 打包
# go env -w GOPROXY=https://goproxy.cn,direct
go mod vendor
peer lifecycle chaincode package asset.tar.gz --path ./chaincode/asset-transfer --lang golang --label asset_1


## 设置环境变量 as Org1 Admin
peer lifecycle chaincode install asset.tar.gz # as Org1
# 查询package id
peer lifecycle chaincode queryinstalled
#Package ID: asset_1:ad70169adf42e85ff8c8516314221fff3661a0c5af346eb4f8c0aa185a728e1b, Label: asset_1
# 批准链码 as Org1
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.test.com \
 --channelID mychannel --name asset --version 1.0 \
 --init-required --package-id asset_1:ad70169adf42e85ff8c8516314221fff3661a0c5af346eb4f8c0aa185a728e1b --sequence 1 \
 --tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem

## 设置环境变量 as Org2
peer lifecycle chaincode install asset.tar.gz
# 批准 通道大部分都要批准 as Org2
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.test.com \
 --channelID mychannel --name asset --version 1.0 \
 --init-required --package-id asset_1:ad70169adf42e85ff8c8516314221fff3661a0c5af346eb4f8c0aa185a728e1b --sequence 1 \
 --tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem


###  检查批准结果
peer lifecycle chaincode checkcommitreadiness --channelID mychannel \
--name asset --version 1.0 --init-required --sequence 1 \
--tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem \
--output json

# 提交 一次即可
# localhost实际节点的地址
# 使用cli需要自己来指定背书节点
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.test.com \
--channelID mychannel --name asset --version 1.0 --sequence 1 \
--init-required --tls --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem \
--peerAddresses localhost:7051 \
--tlsRootCertFiles $(pwd)/organizations/crypto/peerOrganizations/org1.test.com/peers/peer0.org1.test.com/tls/ca.crt \
--peerAddresses localhost:9051 \
--tlsRootCertFiles $(pwd)/organizations/crypto/peerOrganizations/org2.test.com/peers/peer0.org2.test.com/tls/ca.crt






# 调用
# 使用CLI需要指定背书节点，使用SDK使用gateway peers来转发
# --isInit 本次调用作为init,兼容以前的链码   InitLedger/空调用也可以,且只能调用一次;后面不能使用--isInit
# 批准是指定需要init, 则必须先init才能调用链码
peer chaincode invoke -o localhost:7050 --isInit  \
--ordererTLSHostnameOverride orderer.test.com \
--tls true --cafile $(pwd)/organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/msp/tlscacerts/tlsca.test.com-cert.pem \
-C mychannel -n asset \
--peerAddresses localhost:7051 \
--tlsRootCertFiles $(pwd)/organizations/crypto/peerOrganizations/org1.test.com/peers/peer0.org1.test.com/tls/ca.crt \
--peerAddresses localhost:9051 \
--tlsRootCertFiles $(pwd)/organizations/crypto/peerOrganizations/org2.test.com/peers/peer0.org2.test.com/tls/ca.crt \
-c '{"Args":["InitLedger"]}'

# 调用
peer chaincode query -C mychannel -n asset -c '{"Args":["GetAllAssets"]}'

# invoke 会记录账本---背书---排序---提交
# query 直接返回结果（可靠吗）



##################################################
# 更新配置流程
peer channel fetch config config_block.pb -o orderer.test.com:7050 -c $CHANNEL_NAME --tls --cafile $ORDERER_CA

configtxlator proto_decode --type=common.Block --input=./channel-artifacts/genesis_block.pb | jq .data.data[0].payload.data.config > ./channel-artifacts/genesis_block.json

cp config.json modified_config.json

vim modified_config.json

# 修改块的Config
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
# 原先块的config
configtxlator proto_encode --input config.json --type common.Config --output config.pb
# 更新部分
configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output diff_config.pb
# 更新部分写入json
configtxlator proto_decode --input diff_config.pb --type common.ConfigUpdate | jq . > diff_config.json
# 添加元数据text
echo '{"payload":{"header":{"channel_header":{"channel_id":"mychannel", "type":2}},"data":{"config_update":'$(cat diff_config.json)'}}}' | jq . > diff_config_envelope.json

# 生成更新块
configtxlator proto_encode --input diff_config_envelope.json --type common.Envelope --output diff_config_envelope.pb
# admin签名
peer channel signconfigtx -f diff_config_envelope.pb
# commit
peer channel update -f diff_config_envelope.pb -c $CHANNEL_NAME -o orderer.test.com:7050 --tls --cafile $ORDERER_CA