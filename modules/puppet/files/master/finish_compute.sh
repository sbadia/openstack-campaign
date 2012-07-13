#!/bin/bash
echo -en '--flat_interface=eth0\n--flat_injected=True\n' >> /etc/nova/nova.conf
sed -e 's/FlatManager/FlatDHCPManager/' -i /etc/nova/nova.conf
/etc/init.d/nova-compute restart
/etc/init.d/nova-volume restart
