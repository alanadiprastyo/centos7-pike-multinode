#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#install & setting glance for image service

source os.conf
source admin-openrc
[ -d ./tmp ] || mkdir ./tmp

yum -y install openstack-neutron-openvswitch

[ ! -f /etc/neutron/neutron.conf.orig ] && cp -v /etc/neutron/neutron.conf /etc/neutron/neutron.conf.orig
cat << _EOF_ > ./tmp/neutron.conf
[DEFAULT]
transport_url = rabbit://openstack:${PASSWORD}@${CONT_MAN_IP}
auth_strategy = keystone
[agent]
[cors]
[database]
[keystone_authtoken]
auth_uri = http://${CONT_MAN_IP}:5000
auth_url = http://${CONT_MAN_IP}:35357
memcached_servers = ${CONT_MAN_IP}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = $PASSWORD
[matchmaker_redis]
[nova]
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

[ ! -f /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig ] && cp -v /etc/neutron/plugins/ml2/openvswitch_agent.ini /etc/neutron/plugins/ml2/openvswitch_agent.ini.orig
cat << _EOF_ > ./tmp/openvswitch_agent.ini.compute
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
local_ip=$COMP_MAN_IP
bridge_mappings=extnet:br-ex
[securitygroup]
firewall_driver=neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
[xenapi]
_EOF_
cp ./tmp/openvswitch_agent.ini.compute /etc/neutron/plugins/ml2/openvswitch_agent.ini

cat << _EOF_ > ./tmp/ifcfg-br-ex.compute
PROXY_METHOD=none
BROWSER_ONLY=no
DEFROUTE=yes
ONBOOT=yes
IPADDR=$COMP_EXT_IP
PREFIX=24
DEVICE=br-ex
NAME=br-ex
DEVICETYPE=ovs
OVSBOOTPROTO=none
TYPE=OVSBridge
OVS_EXTRA="set bridge br-ex fail_mode=standalone"
_EOF_
cp ./tmp/ifcfg-br-ex.compute /etc/sysconfig/network-scripts/ifcfg-br-ex

cp ./tmp/ifcfg-eth1 /etc/sysconfig/network-scripts/ifcfg-eth1

ifdown eth1; ifdown br-ex; ifup br-ex; ifup eth1

systemctl enable neutron-openvswitch-agent.service
systemctl restart neutron-openvswitch-agent.service
systemctl status neutron-openvswitch-agent.service
