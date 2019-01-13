# kubernetes_helper

安装kubernetes的脚本

# 单机安装
## Ubuntu16.04安装
操作系统:Ubuntu16.04
硬件配置:2核4GB阿里云ECS
权限: root
### 安装步骤
1. 安装git,下载本代码仓库
```
apt-get update -y && apt-get upgrade -y && apt install git
git clone https://github.com/gomode/kubernetes_helper.git
```

1. 执行安装脚本
```
cd kubernetes_helper/setup/
./setup_k8s_ubuntu_1604.sh
```
执行过程中需要如如两个参数:
    + 请输入想要安装的k8s版本(1.13.1),默认1.13.1，如果想要自定义，按照格式输入即可，否则直接回车
    + 请输入远程访问k8s需要的域名/公网IP，最好自己输入一个域名，然后把域名指向本机公网IP即可，也可以直接输入gongwangIP
      - 这个地址是后面从其他机器通过kubectl的地址
      — 到时候修改.kube/config下面的 server地址即可
    + 请输入访问集群测试API接口的域名，这个是用于测试集群内服务是否部署成功的
      - 这个域名通常配置为整个后端的接口域名
      - 整个脚本执行完成以后可以通过域名/healthz来测试，成功的话返回ok。


# 问题排查

1. kubelet日志查看
```
journalctl -f -u kubelet
```


```
echo "set fileencodings=utf-8,gbk,utf-16le,cp1252,iso-8859-15,ucs-bom" >> /etc/vim/vimrc
echo "set set termencoding=utf-8" >> /etc/vim/vimrc
echo "set set encoding=utf-8" >> /etc/vim/vimrc
```


```
source <(kubectl completion bash)
```