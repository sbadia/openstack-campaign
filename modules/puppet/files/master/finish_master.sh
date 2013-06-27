#!/bin/bash
net_dev=$(cat /etc/network/interfaces |grep 'iface eth' | head -1 |awk '{ print $2 }')
ns_ip=$(cat /etc/resolv.conf |grep nameserver|head -1|awk '{ print $2 }')
ip addr add 10.0.0.1/20 dev br100
mysql -D nova -e "update networks set dns1='$ns_ip' where dns1='8.8.4.4';"
mysql -D nova -e "update networks set bridge_interface='$net_dev' where bridge_interface='br100';"
echo -en "--flat_interface=$net_dev\n--flat_injected=True\n" >> /etc/nova/nova.conf
sed -e 's/FlatManager/FlatDHCPManager/' -i /etc/nova/nova.conf
/etc/init.d/nova-network restart
# https://answers.launchpad.net/nova/+question/152528
ip link set dev br100 promisc on
