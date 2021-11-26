

用于静态生成证书文件
```
cryptogen generate --config=crypto-config.yaml [--output="crypto-config"]
```

说明：
* 每个组织的配置可以分开,生成的证书在cryto-config
* 可以扩展，cryptogen extend来增加新的证书
