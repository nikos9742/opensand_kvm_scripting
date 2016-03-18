#!/bin/sh
#Clean whitebox.sh


### Add run number to do multiple launches simultaneously CLEANING VERSION
runnb=''
separator='_'
if [ -f $HOME/run* ]
 then
  runnb=$(basename "$HOME/run*") | tr -d run
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo 'The number of platform running is ' $runnb
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
 else
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo 'No running platform was detected Check manually with : virsh list'
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo " Legacy mode Cleaning single platform"
  separator=''
fi

virsh shutdown OpensandGW1$separator$runnb
virsh shutdown OpensandGW2$separator$runnb
virsh shutdown OpensandSAT1$separator$runnb
virsh shutdown OpensandST1$separator$runnb

virsh destroy OpensandGW1$separator$runnb
virsh destroy OpensandGW2$separator$runnb
virsh destroy OpensandSAT1$separator$runnb
virsh destroy OpensandST1$separator$runnb

virsh undefine OpensandGW1$separator$runnb
virsh undefine OpensandGW2$separator$runnb
virsh undefine OpensandSAT1$separator$runnb
virsh undefine OpensandST1$separator$runnb

echo 'Cleaning $HOME/whitebox$separator$runnb'
rm -rf $HOME/whitebox$separator$runnb

#((runnb--))
#rm $HOME/run*
#touch $HOME/run$runnb
if
 



