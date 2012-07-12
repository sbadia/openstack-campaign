#!/bin/bash
ip addr add 10.0.0.1/24 dev br100
mysql -D nova -e "update networks set dns1='172.16.79.106' where dns1='8.8.4.4';"
mysql -D nova -e "update networks set bridge_interface='eth0' where bridge_interface='br100';"
echo -en '--flat_interface=eth0\n--flat_injected=True' >> /etc/nova/nova.conf
sed -e 's/FlatManager/FlatDHCPManager' -i /etc/nova/nova.conf
/etc/init.d/nova-network restart
