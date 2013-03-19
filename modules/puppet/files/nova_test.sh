#!/bin/bash

set -e

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
echo "--> download $IMG image..."
wget http://apt.grid5000.fr/cloud/$IMG.img
# import that image into glance
echo "--> add downloaded image to glance..."
glance add name="$NAME-amd64" is_public=true container_format=ovf disk_format=qcow2 < $IMG.img
IMAGE_ID=`glance index | grep "$NAME-amd64" | head -1 |  awk -F' ' '{print $1}'`
## create a pub key
echo "--> create a ssh key (key_$NAME)..."
ssh-keygen -f /tmp/id_rsa -t rsa -N ''
nova keypair-add --pub_key /tmp/id_rsa.pub key_$NAME
echo "--> init (tcp 22/ tcp 80/ icmp) security groups (${NAME}_test)..."
nova secgroup-create ${NAME}_test "$NAME test security group"
nova secgroup-add-rule ${NAME}_test tcp 22 22 0.0.0.0/0
nova secgroup-add-rule ${NAME}_test tcp 80 80 0.0.0.0/0
nova secgroup-add-rule ${NAME}_test icmp -1 -1 0.0.0.0/0
#floating_ip=`nova floating-ip-create | grep None | awk '{print $2}'`
echo "--> boot a vm (${NAME}_vm)..."
nova boot --flavor 1 --security_groups ${NAME}_test --image ${IMAGE_ID} --key_name key_$NAME ${NAME}_vm
sleep 5
echo "--> show ${NAME}_vm status..."
nova show ${NAME}_vm
# wait for the server to boot
sleep 20
#nova add-floating-ip precise_vm $floating_ip
sleep 10
IP=`nova show ${NAME}_vm |grep novanetwork|awk '{print $5}'`
echo "--> It's ok, you can sshing by run this command..."
echo "ssh ${NAME}@${IP} -i /tmp/id_rsa"
echo -en "\nFor dashboard (from your laptop):\nssh -L 8888:`hostname -s`:80 `hostname -d | cut -d '.' -f 1`.g5k\nand go to http://localhost:8888\n"
#ssh cirros@${IP} -i /tmp/id_rsa
#nova show cirros_vm
## create ec2 credentials
#export SERVICE_TOKEN=
#export SERVICE_ENDPOINT=
#keystone catalog --service=ec2
#keystone ec2-credentials-create
#keystone ec2-credentials-list
#. /root/openrc
