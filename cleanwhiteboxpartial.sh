#!/bin/sh
#Clean WhiteboxFULL2.sh

virsh shutdown OpensandGW1
virsh shutdown OpensandGW2
virsh shutdown OpensandSAT1
virsh shutdown OpensandST1

virsh destroy OpensandGW1
virsh destroy OpensandGW2
virsh destroy OpensandSAT1
virsh destroy OpensandST1

virsh undefine OpensandGW1
virsh undefine OpensandGW2
virsh undefine OpensandSAT1
virsh undefine OpensandST1

rm -rf $HOME/whitebox

