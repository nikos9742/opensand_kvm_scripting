#!/bin/sh
#Deploy 2 service provider VM on existant platform

####################################################################################
## Create a file with some user-data in it for OpensandGW1
cat > $HOME/whitebox/my-cloud-configSP1.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandSP1
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

cat > $HOME/whitebox/my-user-scriptSP1.txt <<EOF
#!/bin/sh
#OpensandSP1 Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
#Enabling second network interface
echo "auto eth1" >> /etc/network/interfaces.d/eth1.cfg
echo "iface eth1 inet static" >> /etc/network/interfaces.d/eth1.cfg
echo "\t address 172.0.16.5" >> /etc/network/interfaces.d/eth1.cfg
echo "\t netmask 255.255.255.0" >> /etc/network/interfaces.d/eth1.cfg
#restart networking services
/etc/init.d/networking restart
apt-get -y --force-yes install python-pip git
pip install pyusb

reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox/combined-userdataSP1.txt $HOME/whitebox/my-user-scriptSP1.txt:text/x-shellscript $HOME/whitebox/my-cloud-configSP1.txt:text/cloud-config

####################################################################################
## Create a file with some user-data in it for OpensandGW1
cat > $HOME/whitebox/my-cloud-configSP2.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandSP2
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

cat > $HOME/whitebox/my-user-scriptSP2.txt <<EOF
#!/bin/sh
#OpensandSP2 Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
#Enabling second network interface
echo "auto eth1" >> /etc/network/interfaces.d/eth1.cfg
echo "iface eth1 inet static" >> /etc/network/interfaces.d/eth1.cfg
echo "\t address 172.0.16.6" >> /etc/network/interfaces.d/eth1.cfg
echo "\t netmask 255.255.255.0" >> /etc/network/interfaces.d/eth1.cfg
#restart networking services
/etc/init.d/networking restart
apt-get -y --force-yes install python-pip git
pip install pyusb

reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox/combined-userdataSP2.txt $HOME/whitebox/my-user-scriptSP2.txt:text/x-shellscript $HOME/whitebox/my-cloud-configSP2.txt:text/cloud-config

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox/my-seedSP2.img $HOME/whitebox/combined-userdataSP2.txt

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox/my-seedSP1.img $HOME/whitebox/combined-userdataSP1.txt

## Create a delta disk to keep our .orig file pristine
qemu-img create -f qcow2 -b $HOME/whitebox/disk.img.orig $HOME/whitebox/diskSP1.img
## Create a delta disk to keep our .orig file pristine
qemu-img create -f qcow2 -b $HOME/whitebox/disk.img.orig $HOME/whitebox/diskSP2.img

#OpensandSP1
virt-install --connect qemu:///system --hvm -n OpensandSP1 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox/diskSP1.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox/my-seedSP1.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import
#OpensandSP2
virt-install --connect qemu:///system --hvm -n OpensandSP2 -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox/diskSP2.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox/my-seedSP2.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

## Mac Address randomization
PREFIXMAC='00:'
MACSP1=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MACSP2=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MACSP3=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MACSP4=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`

## Create network external for VM OpensandGW1
cat > $HOME/whitebox/ovs_network_kvm_SP1.xml <<EOF
<interface type='bridge'>
<mac address='$PREFIXMAC$MACSP1'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW1
cat > $HOME/whitebox/ovs_network_kvm_SP1_int.xml <<EOF
<interface type='bridge'>
<mac address='$PREFIXMAC$MACSP2'/>
<source bridge='ovsbr2'/>
<virtualport type='openvswitch'/>
</interface>
EOF
## Create network external for VM OpensandGW1
cat > $HOME/whitebox/ovs_network_kvm_SP2.xml <<EOF
<interface type='bridge'>
<mac address='$PREFIXMAC$MACSP3'/>
<source bridge='ovsbr1'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW1
cat > $HOME/whitebox/ovs_network_kvm_SP2_int.xml <<EOF
<interface type='bridge'>
<mac address='$PREFIXMAC$MACSP4'/>
<source bridge='ovsbr2'/>
<virtualport type='openvswitch'/>
</interface>
EOF

## attach network to VM
virsh attach-device --domain OpensandSP1 $HOME/whitebox/ovs_network_kvm_SP1.xml
virsh attach-device --domain OpensandSP1 $HOME/whitebox/ovs_network_kvm_SP1_int.xml
## attach network to VM
virsh attach-device --domain OpensandSP2 $HOME/whitebox/ovs_network_kvm_SP2.xml
virsh attach-device --domain OpensandSP2 $HOME/whitebox/ovs_network_kvm_SP2_int.xml

