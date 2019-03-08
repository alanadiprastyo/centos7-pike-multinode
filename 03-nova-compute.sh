#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#install & setting glance for image service

source os.conf
source admin-openrc
[ -d ./tmp ] || mkdir ./tmp


yum -y install openstack-nova-compute

[ ! -f /etc/nova/nova.conf.orig ] && cp -v /etc/nova/nova.conf /etc/nova/nova.conf.orig
cat << _EOF_ > ./tmp/nova.conf.compute
[DEFAULT]
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:${PASSWORD}@${CONT_MAN_IP}
my_ip = $COMP_MAN_IP
use_neutron = True
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api]
auth_strategy = keystone
[api_database]
[barbican]
[cache]
[cells]
[cinder]
[compute]
[conductor]
[console]
[consoleauth]
[cors]
[crypto]
[database]
[devices]
[ephemeral_storage_encryption]
[filter_scheduler]
[glance]
api_servers = http://${CONT_MAN_IP}:9292
[guestfs]
[healthcheck]
[hyperv]
[ironic]
[key_manager]
[keystone]
[keystone_authtoken]
auth_url = http://${CONT_MAN_IP}:5000/v3
memcached_servers = ${CONT_MAN_IP}:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = $PASSWORD
[libvirt]
virt_type = kvm
[matchmaker_redis]
[metrics]
[mks]
[neutron]
url = http://${CONT_MAN_IP}:9696
auth_url = http://${CONT_MAN_IP}:35357
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $PASSWORD
[notifications]
[osapi_v21]
[oslo_concurrency]
lock_path = /var/lib/nova/tmp
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[pci]
[placement]
os_region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://${CONT_MAN_IP}:5000/v3
username = placement
password = $PASSWORD
[quota]
[rdp]
[remote_debug]
[scheduler]
[serial_console]
[service_user]
[spice]
[upgrade_levels]
[vault]
[vendordata_dynamic_auth]
[vmware]
[vnc]
enabled = True
server_listen = 0.0.0.0
server_proxyclient_address = $COMP_MAN_IP
novncproxy_base_url = http://${CONT_MAN_IP}:6080/vnc_auto.html
[workarounds]
[wsgi]
[xenserver]
[xvp]
_EOF_
cp ./tmp/nova.conf.compute /etc/nova/nova.conf

systemctl enable libvirtd.service openstack-nova-compute.service
systemctl restart libvirtd.service openstack-nova-compute.service
systemctl status libvirtd.service openstack-nova-compute.service
