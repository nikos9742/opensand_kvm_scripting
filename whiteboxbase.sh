#!/bin/sh
#Deploy base packages for hybrid KVM/Docker/LXC Openvswitch Whitebox

img_url="https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"
apt-get update
apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virt-manager openvswitch-controller openvswitch-switch openvswitch-datapath-source cloud-utils genisoimage lxc
mkdir $HOME/whitebox
cd $HOME/whitebox
wget --no-check-certificate $img_url -O disk.img.dist

#set network openvswitch for KVM vms

ovs-vsctl add-br ovsbr1
ovs-vsctl add-port ovsbr1 eth1
ifconfig eth1 up
ovs-vsctl add-br ovsbr2
ovs-vsctl add-br ovsbr3

#VM creation
## Convert the compressed qcow file downloaded to a uncompressed qcow2
qemu-img convert -O qcow2 disk.img.dist disk.img.orig

## Create a file with some user-data in it for OpensandGW1
cat > my-user-dataGW1 <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandGW1
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

## create the disk with NoCloud data on it.
cloud-localds my-seedGW1.img my-user-dataGW1

## Create a file with some user-data in it for OpensandGW2
cat > my-user-dataGW2 <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandGW2
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

## create the disk with NoCloud data on it.
cloud-localds my-seedGW2.img my-user-dataGW1

## Create a file with some user-data in it for OpensandSAT1
cat > my-user-dataSAT1 <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandSAT1
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

## create the disk with NoCloud data on it.
cloud-localds my-seedSAT1.img my-user-dataSAT1

## Create a file with some user-data in it for OpensandST1
cat > my-user-dataST1 <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandST1
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

## create the disk with NoCloud data on it.
cloud-localds my-seedST1.img my-user-dataST1


#  genisoimage -output cidata.iso -volid cidata -joliet -rock my-user-dataSAT

## Create a delta disk to keep our .orig file pristine
qemu-img create -f qcow2 -b disk.img.orig diskGW1.img
qemu-img create -f qcow2 -b disk.img.orig diskGW2.img
qemu-img create -f qcow2 -b disk.img.orig diskSAT1.img
qemu-img create -f qcow2 -b disk.img.orig diskST1.img

## Create the VM with the option for cloud-init and openvswitch network
# virt-install --connect qemu:///system --hvm -n opensandKVMSAT -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskSAT.img,device=disk,bus=virtio --disk my-seedSAT.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandGW1
virt-install --connect qemu:///system --hvm -n OpensandGW1 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskGW1.img,format=qcow2,device=disk,bus=virtio --disk my-seedGW1.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandGW2
virt-install --connect qemu:///system --hvm -n OpensandGW2 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskGW2.img,format=qcow2,device=disk,bus=virtio --disk my-seedGW2.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandSAT1
virt-install --connect qemu:///system --hvm -n OpensandSAT1 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskSAT1.img,format=qcow2,device=disk,bus=virtio --disk my-seedSAT1.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandST1
virt-install --connect qemu:///system --hvm -n OpensandST1 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskST1.img,format=qcow2,device=disk,bus=virtio --disk my-seedST1.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

## test with kvm raw
#   kvm -net nic -net user -hda diskSAT.img -hdb my-seedSAT.img -m 512



## Create network external for VM OpensandGW1
cat > ovs_network_kvm_gw1.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b1:b7'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW1
cat > ovs_network_kvm_gw1_int.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b1:b8'/>
<source bridge='ovsbr2'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandGW2
cat > ovs_network_kvm_gw2.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b2:b7'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW2
cat > ovs_network_kvm_gw2_int.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b2:b8'/>
<source bridge='ovsbr2'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandSAT1
cat > ovs_network_kvm_sat1.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b3:b7'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandST1
cat > ovs_network_kvm_st1.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b4:b7'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandST1
cat > ovs_network_kvm_st1_int.xml <<EOF
<interface type='bridge'>
<mac address='52:54:00:71:b4:b8'/>
<source bridge='ovsbr3'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## attach network to VM
virsh attach-device --domain OpensandGW1 ovs_network_kvm_gw1.xml
virsh attach-device --domain OpensandGW1 ovs_network_kvm_gw1_int.xml
virsh attach-device --domain OpensandGW2 ovs_network_kvm_gw2.xml
virsh attach-device --domain OpensandGW2 ovs_network_kvm_gw2_int.xml
virsh attach-device --domain OpensandSAT1 ovs_network_kvm_sat1.xml
virsh attach-device --domain OpensandST1 ovs_network_kvm_st1.xml
virsh attach-device --domain OpensandST1 ovs_network_kvm_st1_int.xml



