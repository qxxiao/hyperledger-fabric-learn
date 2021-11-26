

> 说明：根据samples搭建自定义的fabric网络
学习fabric的测试网络，了解的基本架构和启动流程，简化最小的启动流程，方便后面自定义网络配置

## 目标 
1. 主要是熟悉网络搭建的流程，和配置文件的使用
2. 自定义组织/数量
3. 先使用cryptogen来进行静态证书生成 yaml
4. 通道的创建流程---加入通道---锚节点更新（系统通道配置/通道配置---通道配置文件/块）
5. 链码的生命周期
6. 具体的链码开发



## 通道创建
参考：  
* https://hyperledger-fabric.readthedocs.io/en/latest/create_channel/create_channel_participation.html  
* https://hyperledger-fabric.readthedocs.io/en/latest/create_channel/create_channel_test_net.html  
  
使用v2.3,说明:   
* 不需要先创建系统通道，及其创世区块genesis.block, 直接创建应用程序通道的创世区块（也是使用configtx.yaml）
* 新版本中docker-compose中配置了环境变量，覆盖了orderer.yaml，不启用系统通道


步骤：  
1. 配置排序节点
	* 创建排序组织MSP并生成排序节点证书
	* 为每个排序节点配置 orderer.yaml 文件
	`General.BootstrapMethod`- 将此值设置为none,因为不再需要系统通道，每个排序节点上的orderer.yaml文件都需要配置，这意味着不需要或使用引导块来启动排序节点。(也可以设置环境变量)
	`ChannelParticipation.Enabled`:- 将此值设置true为在订购者上启用此功能

2. 生成应用程序通道的创世块
	首先需要在configtx.yaml中定义组织和anchorPeers,创建其MSP
	流程，先创建创世块，使用channel join提交给排序节点, 并且可以与通道的其他成员共享---同意通道的配置
	* FABRIC_CFG_PATH环境变量设置为包含configtx.yaml文件本地副本的目录的路径
	* configtxgen -profile TwoOrgsApplicationGenesis -outputBlock $DIRECTORY/genesis_block.pb -channelID ${channelName}

3. 使用osnadmin将第一个orderer添加到通道
```
export OSN_TLS_CA_ROOT_CERT=./organizations/crypto/ordererOrganizations/test.com/orderers/orderer.test.com/tls/ca.crt
export ADMIN_TLS_SIGN_CERT=./organizations/crypto/ordererOrganizations/test.com/users/Admin@test.com/tls/client.crt
export ADMIN_TLS_PRIVATE_KEY=./organizations/crypto/ordererOrganizations/test.com/users/Admin@test.com/tls/client.key
```
-------------------------------------------------
由于osnadmin CLI和 orderer之间的连接需要双向TLS，因此您需要在每个命令上传递--client-cert和--client-key参数
```
osnadmin channel join \
--channelID ${channelName}  --config-block $DIRECTORY/genesis_block.pb \
-o localhost:7053 --ca-file $OSN_TLS_CA_ROOT_CERT \
--client-cert $ADMIN_TLS_SIGN_CERT \
--client-key $ADMIN_TLS_PRIVATE_KEY
```

4. 如果有多个排序节点，加入其他排序节点
   需要改变命令中的端点

如果随着时间的推移，可能需要将额外的排序节点添加到通道的同意者集中   
https://hyperledger-fabric.readthedocs.io/en/latest/create_channel/create_channel_participation.html#deploy-a-new-set-of-orderers


5. 加入组织的peer到通道
频道创建完成后，您可以按照正常流程将peer加入频道并配置anchor peer  
作为通道成员的所有对等组织都可以使用`peer channel fetch`命令从排序服务中获取通道创世块。
然后，组织可以使用创世块通过`peer channel join`命令将peer 加入通道  
一旦peer加入通道，将通过排序服务 检索通道上的生成的块来构建区块链账本

## 更改配置
1. [https://hyperledger-fabric.readthedocs.io/en/latest/config_update.html](https://hyperledger-fabric.readthedocs.io/en/latest/config_update.html)
2. [help.sh说明](./utils/help.sh)
