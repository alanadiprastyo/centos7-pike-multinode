#!/bin/bash
#Author1 = Utian Ayuba
#Author2 = Alan Adi Prastyo
#Env for Compute

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