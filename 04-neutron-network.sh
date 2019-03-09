#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#install & setting glance for image service

source os.conf
source admin-openrc
[ -d ./tmp ] || mkdir ./tmp

##### Neutron Networking Service #####

yum -y install openstack-neutron openstack-neutron-ml2 openstack-neutron-openvswitch

[ ! -f /etc/neutron/neutron.conf.orig ] && cp -v /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig

cat << _EOF_ > ./tmp/neutron.conf
[DEFAULT]
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
transport_url = rabbit://openstack:${PASSWORD}@${CONT_HOSTNAME}
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
[agent]
[cors]
[keystone_authtoken]
auth_uri = http://${CONT_HOSTNAME}:5000
auth_url = http://${CONT_HOSTNAME}:35357
memcached_servers = ${CONT_HOSTNAME}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = $PASSWORD
[matchmaker_redis]
[oslo_concurrency]
lock_path = /var/lib/neutron/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[quotas]
[ssl]
_EOF_
cp ./tmp/neutron.conf /etc/neutron/neutron.conf

[ ! -f /etc/neutron/plugins/ml2/ml2_conf.ini.orig ] && cp -v /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.orig
cat << _EOF_ > ./tmp/ml2_conf.ini
[DEFAULT]
[l2pop]
[ml2]
type_drivers=vxlan,flat
tenant_network_types=vxlan
mechanism_drivers=openvswitch
extension_drivers=port_security,qos
path_mtu=0
[ml2_type_flat]
flat_networks=*
[ml2_type_geneve]
[ml2_type_gre]
[ml2_type_vlan]
[ml2_type_vxlan]
vni_ranges=10:1000
vxlan_group=224.0.0.1
[securitygroup]
firewall_driver=neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group=True
enable_ipset = true
_EOF_
cp ./tmp/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini

[ ! -f /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig ] && cp -v /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
cat << _EOF_ > ./tmp/openvswitch_agent.ini
[DEFAULT]
[agent]
tunnel_types=vxlan
vxlan_udp_port=4789
l2_population=False
drop_flows_on_start=False
[network_log]
[ovs]
integration_bridge=br-int
tunnel_bridge=br-tun
local_ip=$NET_MAN_IP
bridge_mappings=extnet:br-ex
[securitygroup]
firewall_driver=neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
[xenapi]
_EOF_
cp ./tmp/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini

[ ! -f /etc/neutron/l3_agent.ini.orig ] && cp -v /etc/neutron/l3_agent.ini /etc/neutron/l3_agent.ini.orig
cat << _EOF_ > ./tmp/l3_agent.ini
[DEFAULT]
interface_driver=neutron.agent.linux.interface.OVSInterfaceDriver
agent_mode=legacy
debug=False
[agent]
[ovs]
_EOF_
cp ./tmp/l3_agent.ini /etc/neutron/l3_agent.ini

[ ! -f /etc/neutron/dhcp_agent.ini.orig ] && cp -v /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.orig
cat << _EOF_ > ./tmp/dhcp_agent.ini
[DEFAULT]
interface_driver=neutron.agent.linux.interface.OVSInterfaceDriver
resync_interval=30
enable_isolated_metadata=False
enable_metadata_network=False
debug=False
state_path=/var/lib/neutron
root_helper=sudo neutron-rootwrap /etc/neutron/rootwrap.conf
[agent]
[ovs]
_EOF_
cp ./tmp/dhcp_agent.ini /etc/neutron/dhcp_agent.ini

[ ! -f /etc/neutron/metadata_agent.ini.orig ] && cp -v /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.orig
cat << _EOF_ > ./tmp/metadata_agent.ini
[DEFAULT]
metadata_proxy_shared_secret=e52550a9713f45aa
metadata_workers=4
debug=False
nova_metadata_ip=$NET_MAN_IP
[agent]
[cache]
_EOF_
cp ./tmp/metadata_agent.ini /etc/neutron/metadata_agent.ini

[ -h /etc/neutron/plugin.ini ] || ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini


cat << _EOF_ > ./tmp/ifcfg-br-ex
PROXY_METHOD=none
BROWSER_ONLY=no
DEFROUTE=yes
ONBOOT=yes
IPADDR=$CONT_EXT_IP
PREFIX=24
DEVICE=br-ex
NAME=br-ex
DEVICETYPE=ovs
OVSBOOTPROTO=none
TYPE=OVSBridge
OVS_EXTRA="set bridge br-ex fail_mode=standalone"
_EOF_
cp ./tmp/ifcfg-br-ex /etc/sysconfig/network-scripts/ifcfg-br-ex

cat << _EOF_ > ./tmp/ifcfg-eth1
DEVICE=eth1
NAME=eth1
DEVICETYPE=ovs
TYPE=OVSPort
OVS_BRIDGE=br-ex
ONBOOT=yes
BOOTPROTO=none
_EOF_
cp ./tmp/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-eth1

ifdown eth1; ifdown br-ex; ifup br-ex; ifup eth1

systemctl enable neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service
systemctl restart neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service
systemctl status neutron-server.service neutron-openvswitch-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service neutron-l3-agent.service

openstack extension list --network
openstack network agent list