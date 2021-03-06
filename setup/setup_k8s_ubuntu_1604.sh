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

read -p "请输入访问集群测试API接口的域名,类似api.xxx.com:"  config_api_domain
if [ -z "${config_api_domain}" ];then
  echo "请输入访问集群测试API接口的域名"
fi

hasQuayIO=`cat /etc/hosts | grep quay.io | wc -l`
if [ ${hasQuayIO} -eq 0 ];then
    echo "quay-mirror.qiniu.com quay.io" >> /etc/hosts
fi

apt-get update -y && apt-get upgrade -y 
swapoff -a
echo "——————————————————————————开始安装docker——————————————————————————"
apt-get install -y docker.io
systemctl daemon-reload
systemctl restart docker

echo "——————————————————————————开始安装 kubelet kubeadm kubectl——————————————————————————"
#这里使用了阿里云的源
apt-get update && apt-get install -y apt-transport-https curl 
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=${config_k8s_version}-00 kubeadm=${config_k8s_version}-00 kubectl=${config_k8s_version}-00
apt-mark hold kubelet kubeadm kubectl


echo "——————————————————————————拉取kubeadm必备的镜像——————————————————————————"
# 因为国内无法访问google的源，使用 kubeadm config images list 命令获取需要的镜像
# 然后再利用重新tag标记为目标镜像
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

# 详情参考配置文件
kubeadm init --config=./kubeadm_config.yaml
rm -rf $HOME/.kube
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
# 配置kubectl 自动提示
echo "———————————————————kubernetes安装完毕，开始安装calico——————————————————"

#calico 是一种kubernetes的网络插件，这里也可以选择其他网络插件
# 其他网络插件的安装文档 https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#pod-network
#为了加速镜像下载，这里修改了镜像下载的地址
#原文件地址
#```
#kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
#kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
#```
kubectl apply -f ./calico/rbac-kdd.yaml
kubectl apply -f ./calico/calico.yaml
# 这里需要等待calico 服务启动
isReady=`kubectl get pods --namespace=kube-system  | grep calico | awk '{print $3}'`
while [ "${isReady}" != "Running" ];do
    echo "等待calico服务启动中"
    sleep 10
    isReady=`kubectl get pods --namespace=kube-system  | grep calico | awk '{print $3}'`
done

# 允许master接受调度
# 本来master上面是不会调度pod的，因为我们是单机的，所以必须允许master上面部署pod
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "——————————————————————————开始安装ingress-nginx—————————————————————————"
#安装nginx-ingres
kubectl apply -f ./ingress_nginx_mandatory.yaml
#启动nginx-ingres 服务，使用的是NodePort的模式
kubectl apply -f ./ingress_nginx_service_nodeport.yaml

echo "——————————————————————————开始启动healthz服务——————————————————————————"
kubectl apply -f ./healthz/deployment.yaml
kubectl apply -f ./healthz/service.yaml
sed "s/CONFIG_API_DOMAIN/${config_api_domain}/" ./healthz/ingress.yaml > ./healthz/ingress_config.yaml
kubectl apply -f ./healthz/ingress_config.yaml

isReady=`kubectl get pods --namespace=ingress-nginx  | grep nginx-ingress-controller | awk '{print $3}'`
while [ "${isReady}" != "Running" ];do
    echo "等待nginx-ingress服务启动中"
    sleep 10
    isReady=`kubectl get pods --namespace=ingress-nginx  | grep nginx-ingress-controller | awk '{print $3}'`
done
echo "——————————————————————————安装完毕——————————————————————————"
