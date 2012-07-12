#!/bin/bash

source /root/openrc

OS=$1

if [[ -z "$OS" ]]; then
  echo "bash nova_test.sh [ubuntu|cirros]"
  exit 1
fi

if [[ "$OS" == "ubuntu" ]]; then
  IMG="ubuntu-12.04-server-cloudimg-amd64-disk1"
  NAME="ubuntu"
elif [[ "$OS" == "cirros" ]]; then
  IMG="cirros-0.3.0-x86_64-disk"
  NAME="cirros"
fi

# download
wget http://public.lille.grid5000.fr/~sbadia/$IMG.img
# import that image into glance
glance add name="$NAME-amd64" is_public=true container_format=ovf disk_format=qcow2 < $IMG.img
IMAGE_ID=`glance index | grep "$NAME-amd64" | head -1 |  awk -F' ' '{print $1}'`
## create a pub key
ssh-keygen -f /tmp/id_rsa -t rsa -N ''
nova keypair-add --pub_key /tmp/id_rsa.pub key_$NAME
nova secgroup-create ${NAME}_test "$NAME test security group"
nova secgroup-add-rule ${NAME}_test tcp 22 22 0.0.0.0/0
nova secgroup-add-rule ${NAME}_test tcp 80 80 0.0.0.0/0
nova secgroup-add-rule ${NAME}_test icmp -1 -1 0.0.0.0/0

#floating_ip=`nova floating-ip-create | grep None | awk '{print $2}'`
nova boot --flavor 1 --security_groups ${NAME}_test --image ${IMAGE_ID} --key_name key_$NAME ${NAME}_vm
sleep 5
nova show ${NAME}_vm
# wait for the server to boot
sleep 20
#nova add-floating-ip precise_vm $floating_ip
sleep 10
#ssh ubuntu@$floating_ip -i /tmp/id_rsa
#nova show cirros_vm
## create ec2 credentials
export SERVICE_TOKEN=
export SERVICE_ENDPOINT=
keystone catalog --service=ec2
keystone ec2-credentials-create
keystone ec2-credentials-list
. /root/openrc
