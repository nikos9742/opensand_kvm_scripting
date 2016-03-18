#!/bin/sh
#Deploy base packages for hybrid KVM/Docker/LXC Openvswitch Whitebox
img_url="https://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img"
cache_url="$HOME/trusty-server-cloudimg-amd64-disk1.img"
runnb=0
separator='_'
if [ -f $HOME/dependance_done ]
 then
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Dependance already done in previous runs"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
 else
  apt-get update
  apt-get -y install qemu-kvm libvirt-bin ubuntu-vm-builder bridge-utils virt-manager openvswitch-controller openvswitch-switch openvswitch-datapath-source cloud-utils genisoimage lxc 
  touch $HOME/dependance_done
fi

### Add run number to do multiple launches simultaneously
if [ -f $HOME/run* ]
 then
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "An other platform was launched and is actually running -- Launching another one"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  runnb='$(basename "basename $HOME/run*") | tr -d run'
  let "runnb++"
  #runnb='expr $runnb + 1'
  rm $HOME/run*
  touch $HOME/run$runnb
 else
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "No running platform has been detected from previous run -- Launching First"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  let "runnb++"
  #runnb='expr $runnb + 1'
  touch $HOME/run$runnb
fi

##create work folder in home directory
mkdir $HOME/whitebox$runnb
cd $HOME/whitebox$runnb

##Check for image and copy or download it
if [ -f $HOME/trusty-server-cloudimg-amd64-disk1.img ]
 then 
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Ubuntu Cloud Image exists in HOME no need to download ;)"
  cp $HOME/trusty-server-cloudimg-amd64-disk1.img $HOME/whitebox$runnb/disk.img.dist
 else 
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Ubuntu image is not in HOME :( Wait for download"
  wget --no-check-certificate -P $HOME $img_url
  cp $HOME/trusty-server-cloudimg-amd64-disk1.img $HOME/whitebox$runnb/disk.img.dist
fi

#set network openvswitch for KVM vms
if [ -f $HOME/openvswitch_setup_done ]
 then
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Openvswitch bridge setup already done in previous runs"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
 else
  ovs-vsctl add-br ovsbr1
  ovs-vsctl add-port ovsbr1 eth1
  ifconfig eth1 up
  ovs-vsctl add-br ovsbr2
  ovs-vsctl add-br ovsbr3
  touch $HOME/openvswitch_setup_done
fi

#VM creation
## Convert the compressed qcow file downloaded to a uncompressed qcow2
echo "--------- Uncompressing Image File --------------"
qemu-img convert -O qcow2 $HOME/whitebox$runnb/disk.img.dist $HOME/whitebox$runnb/disk.img.orig
echo "--------------- Uncompressed --------------------"

####################################################################################
## Create a file with some user-data in it for OpensandGW1$separator$runnb
cat > $HOME/whitebox$runnb/my-cloud-configGW1$separator$runnb.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandGW1$separator$runnb
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

cat > $HOME/whitebox$runnb/my-user-scriptGW1$separator$runnb.txt <<EOF
#!/bin/sh
#OpensandGW1$separator$runnb Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
#Enabling second network interface 
echo "auto eth1" >> /etc/network/interfaces.d/eth1.cfg 
echo "iface eth1 inet static" >> /etc/network/interfaces.d/eth1.cfg 
echo "\t address 172."$runnb".16.1" >> /etc/network/interfaces.d/eth1.cfg
echo "\t netmask 255.255.255.0" >> /etc/network/interfaces.d/eth1.cfg

#restart networking services
/etc/init.d/networking restart


reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox$runnb/combined-userdataGW1$separator$runnb.txt $HOME/whitebox$runnb/my-user-scriptGW1$separator$runnb.txt:text/x-shellscript $HOME/whitebox$runnb/my-cloud-configGW1$separator$runnb.txt:text/cloud-config

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox$runnb/my-seedGW1$separator$runnb.img $HOME/whitebox$runnb/combined-userdataGW1$separator$runnb.txt

####################################################################################
## Create a file with some user-data in it for OpensandGW2$separator$runnb
cat > $HOME/whitebox$runnb/my-cloud-configGW2$separator$runnb.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandGW2$separator$runnb
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF

cat > $HOME/whitebox$runnb/my-user-scriptGW2$separator$runnb.txt <<EOF
#!/bin/sh
#OpensandGW2$separator$runnb Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
#Enabling second network interface 
echo "auto eth1" >> /etc/network/interfaces.d/eth1.cfg 
echo "iface eth1 inet static" >> /etc/network/interfaces.d/eth1.cfg 
echo  "\t address 172."$runnb".16.2" >> /etc/network/interfaces.d/eth1.cfg
echo  "\t netmask 255.255.255.0" >> /etc/network/interfaces.d/eth1.cfg

#restart networking services
/etc/init.d/networking restart

reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox$runnb/combined-userdataGW2$separator$runnb.txt $HOME/whitebox$runnb/my-user-scriptGW2$separator$runnb.txt:text/x-shellscript $HOME/whitebox$runnb/my-cloud-configGW2$separator$runnb.txt:text/cloud-config

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox$runnb/my-seedGW2$separator$runnb.img $HOME/whitebox$runnb/combined-userdataGW2$separator$runnb.txt

####################################################################################
## Create a file with some user-data in it for OpensandSAT1$separator$runnb
cat > $HOME/whitebox$runnb/my-cloud-configSAT1$separator$runnb.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandSAT1$separator$runnb
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF
cat > $HOME/whitebox$runnb/my-user-scriptSAT1$separator$runnb.txt <<EOF
#!/bin/sh
#OpensandSAT1$separator$runnb Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox$runnb/combined-userdataSAT1$separator$runnb.txt $HOME/whitebox$runnb/my-user-scriptSAT1$separator$runnb.txt:text/x-shellscript $HOME/whitebox$runnb/my-cloud-configSAT1$separator$runnb.txt:text/cloud-config

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox$runnb/my-seedSAT1$separator$runnb.img $HOME/whitebox$runnb/combined-userdataSAT1$separator$runnb.txt

####################################################################################

## Create a file with some user-data in it for OpensandST1$separator$runnb
cat > $HOME/whitebox$runnb/my-cloud-configST1$separator$runnb.txt <<EOF
#cloud-config
password: bordeaux
chpasswd: { expire: False }
ssh_pwauth: True
hostname: opensandST1$separator$runnb
sudo: ['ALL=(ALL) NOPASSWD:ALL']
apt_upgrade: True
final_message: "The system is finally up, after $UPTIME seconds"
EOF
cat > $HOME/whitebox$runnb/my-user-scriptST1$separator$runnb.txt <<EOF
#!/bin/sh
#OpensandST1$separator$runnb Configuration
#Add the OpenSAND repository
echo "deb http://packages.net4sat.org/opensand trusty stable" | sudo tee /etc/apt/sources.list.d/opensand.list
#Update the list of available packages
apt-get update
#Enabling second network interface 
echo "auto eth1" >> /etc/network/interfaces.d/eth1.cfg 
echo "iface eth1 inet static" >> /etc/network/interfaces.d/eth1.cfg 
echo  "\t address 172."$runnb".17.1" >> /etc/network/interfaces.d/eth1.cfg
echo  "\t netmask 255.255.255.0" >> /etc/network/interfaces.d/eth1.cfg

#restart networking services
/etc/init.d/networking restart

reboot
EOF

#create the mime multipart
write-mime-multipart --output=$HOME/whitebox$runnb/combined-userdataST1$separator$runnb.txt $HOME/whitebox$runnb/my-user-scriptST1$separator$runnb.txt:text/x-shellscript $HOME/whitebox$runnb/my-cloud-configST1$separator$runnb.txt:text/cloud-config

## create the disk with NoCloud data on it.
cloud-localds $HOME/whitebox$runnb/my-seedST1$separator$runnb.img $HOME/whitebox$runnb/combined-userdataST1$separator$runnb.txt
####################################################################################


#  genisoimage -output cidata.iso -volid cidata -joliet -rock my-user-dataSAT

## Create a delta disk to keep our .orig file pristine
qemu-img create -f qcow2 -b $HOME/whitebox$runnb/disk.img.orig $HOME/whitebox$runnb/diskGW1$separator$runnb.img
qemu-img create -f qcow2 -b $HOME/whitebox$runnb/disk.img.orig $HOME/whitebox$runnb/diskGW2$separator$runnb.img
qemu-img create -f qcow2 -b $HOME/whitebox$runnb/disk.img.orig $HOME/whitebox$runnb/diskSAT1$separator$runnb.img
qemu-img create -f qcow2 -b $HOME/whitebox$runnb/disk.img.orig $HOME/whitebox$runnb/diskST1$separator$runnb.img

## Create the VM with the option for cloud-init and openvswitch network
# virt-install --connect qemu:///system --hvm -n opensandKVMSAT -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk diskSAT.img,device=disk,bus=virtio --disk my-seedSAT.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandGW1$separator$runnb
virt-install --connect qemu:///system --hvm -n OpensandGW1$separator$runnb -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox$runnb/diskGW1$separator$runnb.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox$runnb/my-seedGW1$separator$runnb.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandGW2$separator$runnb
virt-install --connect qemu:///system --hvm -n OpensandGW2$separator$runnb -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox$runnb/diskGW2$separator$runnb.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox$runnb/my-seedGW2$separator$runnb.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandSAT1$separator$runnb
virt-install --connect qemu:///system --hvm -n OpensandSAT1$separator$runnb -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox$runnb/diskSAT1$separator$runnb.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox$runnb/my-seedSAT1$separator$runnb.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

#OpensandST1$separator$runnb
virt-install --connect qemu:///system --hvm -n OpensandST1$separator$runnb -r 1024 --vcpus 1 --os-type=linux --os-variant=ubuntutrusty --disk $HOME/whitebox$runnb/diskST1$separator$runnb.img,format=qcow2,device=disk,bus=virtio --disk $HOME/whitebox$runnb/my-seedST1$separator$runnb.img,device=disk,bus=virtio --nonetwork --vnc --noautoconsole --import

## test with kvm raw 
#   kvm -net nic -net user -hda diskSAT.img -hdb my-seedSAT.img -m 512

## Mac Address randomization 
MAC1=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC2=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC3=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC4=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC5=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC6=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
MAC7=`(date; cat /proc/interrupts) | md5sum | sed -r 's/^(.{10}).*$/\1/; s/([0-9a-f]{2})/\1:/g; s/:$//;'`
PREFIXMAC='00:'

## Create network external for VM OpensandGW1$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_GW1$separator$runnb.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC1'/>
  <source bridge='ovsbr1'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW1$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_GW1$separator$runnb_int.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC2'/>
  <source bridge='ovsbr2'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandGW2$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_GW2$separator$runnb.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC3'/>
  <source bridge='ovsbr1'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandGW2$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_GW2$separator$runnb_int.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC4'/>
  <source bridge='ovsbr2'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandSAT1$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_SAT1$separator$runnb.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC5'/>
  <source bridge='ovsbr1'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network external for VM OpensandST1$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_ST1$separator$runnb.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC6'/>
  <source bridge='ovsbr1'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## Create network internal for VM OpensandST1$separator$runnb
cat > $HOME/whitebox$runnb/ovs_network_kvm_ST1$separator$runnb_int.xml <<EOF
<interface type='bridge'>
  <mac address='$PREFIXMAC$MAC7'/>
  <source bridge='ovsbr3'/>
  <virtualport type='openvswitch'/>
</interface>
EOF

## attach network to VM
virsh attach-device --domain OpensandGW1$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_GW1$separator$runnb.xml
virsh attach-device --domain OpensandGW1$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_GW1$separator$runnb_int.xml
virsh attach-device --domain OpensandGW2$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_GW2$separator$runnb.xml
virsh attach-device --domain OpensandGW2$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_GW2$separator$runnb_int.xml
virsh attach-device --domain OpensandSAT1$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_SAT1$separator$runnb.xml
virsh attach-device --domain OpensandST1$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_ST1$separator$runnb.xml
virsh attach-device --domain OpensandST1$separator$runnb $HOME/whitebox$runnb/ovs_network_kvm_ST1$separator$runnb_int.xml
