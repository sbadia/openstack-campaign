#!/bin/bash
net_dev=$(cat /etc/network/interfaces |grep 'iface eth' | head -1 |awk '{ print $2 }')
echo -en "--flat_interface=$net_dev\n--flat_injected=True\n" >> /etc/nova/nova.conf
sed -e 's/FlatManager/FlatDHCPManager/' -i /etc/nova/nova.conf
/etc/init.d/nova-compute restart
/etc/init.d/nova-volume restart
# https://answers.launchpad.net/nova/+question/152528
ip link set dev br100 promisc on
