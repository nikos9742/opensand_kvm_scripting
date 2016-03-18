#!/bin/sh
#Deploy base packages for hybrid KVM/Docker/LXC Openvswitch Whitebox 



apt-get update
apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virt-manager openvswitch-controller openvswitch-switch openvswitch-datapath-source cloud-utils genisoimage lxc 
mkdir $HOME/whitebox
cd $HOME/whitebox
wget --no-check-certificate https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img






