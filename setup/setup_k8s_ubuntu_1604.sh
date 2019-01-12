#!/usr/bin/env bash
set -o errexit
echo "——————————————————————————清时输入相关配置——————————————————————————"
read -p "请输入想要安装的k8s版本(1.13.1):"  config_k8s_version
if [ -z "${config_k8s_version}" ];then
  config_k8s_version="1.13.1"
fi

read -p "请输入远程访问k8s需要的域名/公网IP:"  config_k8s_domain
if [ -z "${config_k8s_domain}" ];then
  echo "您没有输入外部访问的域名/公网地址，只能通过本机访问"
fi

apt-get update -y && apt-get upgrade -y 
swapoff -a
echo "——————————————————————————开始安装docker——————————————————————————"
apt-get install -y docker.io
systemctl daemon-reload
systemctl restart docker

echo "——————————————————————————开始安装 kubelet kubeadm kubectl——————————————————————————"
apt-get update && apt-get install -y apt-transport-https curl 
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=${config_k8s_version}-00 kubeadm=${config_k8s_version}-00 kubectl=${config_k8s_version}-00
apt-mark hold kubelet kubeadm kubectl


echo "——————————————————————————拉取kubeadm必备的镜像——————————————————————————"
# 使用 kubeadm config images list 命令获取需要的镜像 然后再利用重新tag的方式来处理
# kubeadm config images list --kubernetes-version=1.13.1 | awk -F "/" '{print $2}' | xargs -i docker pull mirrorgooglecontainers/{}
k8s_version=`kubelet --version | awk '{print $2}'`
imagesList=`kubeadm config images list --kubernetes-version=${k8s_version}`
for image in $imagesList;
do
    imageName=`echo  $image | awk -F "/" '{print $2}'`
    aliasName="mirrorgooglecontainers/${imageName}"
    #coredns 要单独处理
    if [[ $imageName == coredns* ]];then
         aliasName="coredns/${imageName}"
    fi
    docker pull ${aliasName}
    docker tag docker.io/${aliasName} ${image}
    docker rmi ${aliasName}
done

echo "——————————————————————————开始启动kubernetes——————————————————————————"
sed "s/k8s.customer-domain.com/${config_k8s_domain}/" kubeadm.yaml > kubeadm_config.yaml
sed -i "s/CONFIG_KUBERNETES_VERSION/${k8s_version}/" kubeadm_config.yaml

kubeadm init --config=./kubeadm_config.yaml
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
# 配置kubectl 自动提示
echo "source <(kubectl completion bash)" >> ~/.bashrc
source <(kubectl completion bash)
echo "———————————————————kubernetes安装完毕，10s后安装calico——————————————————"

sleep 10s
echo "——————————————————————————开始安装calico——————————————————————————"
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# 允许master接受调度
kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl apply -f ./healthz/ingress_nginx_service_nodeport.yaml

#安装nginx-ingres
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
#启动nginx-ingres 服务，使用的是NodePort的模式
kubectl apply -f ./ingress_nginx_service_nodeport.yaml
