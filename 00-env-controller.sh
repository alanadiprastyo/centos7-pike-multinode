#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#Env for Controller

#load env os.conf
source os.conf

#check & create directory tmp
[ -d ./tmp ] || mkdir ./tmp

#create file hosts
cat << _EOF_ > ./tmp/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$CONT_MAN_IP $CONT_HOSTNAME
$COMP_MAN_IP $COMP_HOSTNAME
$NET_MAN_IP  $NET_HOSTNAME
_EOF_

#
cp ./tmp/hosts /etc/hosts

##### Firewall Service #####
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl status firewalld.service


##### NTP Service #####
yum -y install chrony
systemctl enable chronyd.service
systemctl restart chronyd.service
systemctl status chronyd.service
chronyc sources

##### Install Addtional Packages #####
yum install -y epel-release
yum install -y htop net-tools

##### OpenStack Packages #####
yum -y install centos-release-openstack-pike
yum -y upgrade
yum -y install python-openstackclient openstack-selinux

##### MariaDB Service #####
yum -y install mariadb mariadb-server python2-PyMySQL

if [ ! -f /etc/my.cnf.d/openstack.cnf ]
  then
cat << _EOF_ > ./tmp/openstack.cnf
[mysqld]
bind-address = $CONT_MAN_IP
default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
_EOF_
  cp ./tmp/openstack.cnf /etc/my.cnf.d/openstack.cnf
  systemctl enable mariadb.service
  systemctl restart mariadb.service
  systemctl status mariadb.service
cat << _EOF_ > ./tmp/mysql_secure_installation
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$PASSWORD') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
mysql -e "FLUSH PRIVILEGES;"
_EOF_
    chmod +x ./tmp/mysql_secure_installation
   ./tmp/mysql_secure_installation
fi

##### RabbitMQ Service #####

yum -y install rabbitmq-server
systemctl enable rabbitmq-server.service
systemctl restart rabbitmq-server.service
systemctl status rabbitmq-server.service
rabbitmqctl add_user openstack $PASSWORD
rabbitmqctl set_permissions openstack ".*" ".*" ".*"


##### Memcached Service #####

yum -y install memcached python-memcached
cat << _EOF_ > ./tmp/etc_sysconfig_memcached
sed -i 's/OPTIONS="-l 127.0.0.1,::1"/OPTIONS="-l 127.0.0.1,::1,$CONT_MAN_IP"/g' /etc/sysconfig/memcached
_EOF_
chmod +x ./tmp/etc_sysconfig_memcached
./tmp/etc_sysconfig_memcached
systemctl enable memcached.service
systemctl restart memcached.service
systemctl status memcached.service

##### Etcd Service #####

yum -y install etcd
[ ! -f /etc/etcd/etcd.conf.orig ] && cp -v /etc/etcd/etcd.conf /etc/etcd/etcd.conf.orig
cat << _EOF_ > ./tmp/etcd.conf
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://${CONT_MAN_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${CONT_MAN_IP}:2379"
ETCD_NAME="controller"
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${CONT_MAN_IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${CONT_MAN_IP}:2379"
ETCD_INITIAL_CLUSTER="controller=http://${CONT_MAN_IP}:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER_STATE="new"
_EOF_
cp ./tmp/etcd.conf /etc/etcd/etcd.conf
systemctl enable etcd
systemctl restart etcd
systemctl status etcd



