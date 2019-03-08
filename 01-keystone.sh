#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#install & setting keystone for identity service

#load env os.conf
source os.conf
[ -d ./tmp ] || mkdir ./tmp


##### Keystone Identity Service #####

cat << _EOF_ > ./tmp/keystonedb
mysql -u root -p$PASSWORD -e "SHOW DATABASES;" | grep keystone > /dev/null 2>&1 && echo "keystone database already exists" || mysql -u root -p$PASSWORD -e "CREATE DATABASE keystone; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '$PASSWORD'; GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '$PASSWORD';"
_EOF_
chmod +x ./tmp/keystonedb
./tmp/keystonedb

yum -y install openstack-keystone httpd mod_wsgi

[ ! -f /etc/keystone/keystone.conf.orig ] && cp -v /etc/keystone/keystone.conf /etc/keystone/keystone.conf.orig
cat << _EOF_ > ./tmp/keystone.conf
[DEFAULT]
[application_credential]
[assignment]
[auth]
[cache]
[catalog]
[cors]
[credential]
[database]
connection = mysql+pymysql://keystone:${PASSWORD}@${CONT_MAN_IP}/keystone
[domain_config]
[endpoint_filter]
[endpoint_policy]
[eventlet_server]
[federation]
[fernet_tokens]
[healthcheck]
[identity]
[identity_mapping]
[ldap]
[matchmaker_redis]
[memcache]
[oauth1]
[oslo_messaging_amqp]
[oslo_messaging_kafka]
[oslo_messaging_notifications]
[oslo_messaging_rabbit]
[oslo_messaging_zmq]
[oslo_middleware]
[oslo_policy]
[paste_deploy]
[policy]
[profiler]
[resource]
[revoke]
[role]
[saml]
[security_compliance]
[shadow_users]
[signing]
[token]
provider = fernet
[tokenless_auth]
[trust]
[unified_limit]
_EOF_
cp ./tmp/keystone.conf /etc/keystone/keystone.conf


cat << _EOF_ > ./tmp/keystone_db_sync
su -s /bin/sh -c "keystone-manage db_sync" keystone
_EOF_
chmod +x ./tmp/keystone_db_sync
./tmp/keystone_db_sync

keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password $PASSWORD --bootstrap-admin-url http://${CONT_HOSTNAME}:35357/v3/ --bootstrap-internal-url http://${CONT_HOSTNAME}:5000/v3/ --bootstrap-public-url http://${CONT_HOSTNAME}:5000/v3/ --bootstrap-region-id RegionOne

cat << _EOF_ > ./tmp/httpd.conf
sed -i 's/#ServerName www.example.com:80/ServerName $CONT_HOSTNAME/g' /etc/httpd/conf/httpd.conf
_EOF_
chmod +x  ./tmp/httpd.conf
./tmp/httpd.conf
[ -h /etc/httpd/conf.d/wsgi-keystone.conf ] || ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl restart httpd.service
systemctl status httpd.service

#edit
source admin-openrc
openstack project list | grep service > /dev/null 2>&1 && echo "service project already exist" || openstack project create --domain default --description "Service Project" service
openstack project list
openstack role list | grep user > /dev/null 2>&1 && echo "user role already exist" || openstack role create user
openstack role list
openstack token issue
openstack endpoint list
