# kubernetes配置相关的脚本

## 通过kubernetes Secret配置读取私有仓库镜像
修改文件create_private_docker_repo_secret.sh
配置好必须的参数并执行
```
./create_private_docker_repo_secret.sh
```

## 给Node节点增加label
```
kubectl label nodes izbp11rddwt5ebkv0ux7o0z cluster=main
```