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

3. 执行安装脚本
```
cd kubernetes_helper/setup/
./setup_k8s_ubuntu_1604.sh
```

