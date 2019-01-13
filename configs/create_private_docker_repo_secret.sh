#!/bin/sh
#配置好下面的私有仓库的参数
config_docker_domain=
config_docker_username=
config_docker_password=
config_docker_email=

# 创建一个私有仓库的密码Secret
kubectl create secret docker-registry registrysecret \
 --docker-server=${config_docker_domain} \
 --docker-username=${config_docker_username} \
 --docker-password=${config_docker_password} \
 --docker-email=${config_docker_email}

# 配置serviceaccount，默认使用 registrysecret 作为私有仓库的密码文件
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "registrysecret"}]}'