#!/bin/bash

# iSCSI:
export IP="192.168.2.5"
export PORTAL="${IP}:3260"
export TARGETNAME="iqn.2000-01.com.synology:lanas01.Target-3.b0913d77d79"
export DISKDEV=""

# encrypted partition:
export CRYPTNAS="crypt_lanas01_bakmlc5"
export MNTNAS="/mnt/lanas01_bakmlc5"

# ----------------------------------------------------------------------------
# if ${MNTNAS} path does not exist, then create it
if ! [ -d ${MNTNAS} ] ; then
  mkdir -p ${MNTNAS}
fi

# ----------------------------------------------------------------------------
# check number of arguments and the argument itself:
if [[ $# -ne 1 ]] || ! ( [[ $1 = "mount" ]] || [[ $1 = "mountenc" ]] || [[ $1 = "umount" ]] ) ; then
  echo " $0 error: one argument needed: either 'mount', 'mountenc' or 'umount'" 
  echo "     mount    : mounts and asks for password to decrypt the share"
  echo "     mountenc : \"mounts\" only the encrypted partition (e.g. for copying the encrypted data to USB-drive"  
  echo "     umount   : closes and unmounts the decrypted share"
  exit 1
fi

export JOBTODO=$1
# ----------------------------------------------------------------------------


# ----------------------------------------------------------------------------
#function assignDISKDEV() {
#  tmp=$(ls -l $(find /dev/disk/by-id/ -iname "*scsi*"))
#  export DISKDEV=${tmp##*/}
#}



##############################################################################
if [[ ${JOBTODO} = "mount" ]] || [[ ${JOBTODO} = "mountenc" ]] ; then ######## if mount... ###

  # discover IQN:
  iscsiadm -m discovery -t st -p "${IP}" 

  iscsiadm -m node


  # make device available: 
  iscsiadm -m node --targetname "${TARGETNAME}" --portal "${PORTAL}" --login

  sleep 2s

  # find the correct DISKDEV (i.e. the latest one):
  for tmp in "$(ls -lrt /dev/disk/by-id/*scsi*)" ; do
    echo "${tmp}"
  done
  export DISKDEV=${tmp##*/}
  echo "DISKDEV=${DISKDEV}"

  # check DISKDEV:
  if [ $(find /dev/disk/by-id/ -lname "*${DISKDEV}" | grep scsi) ] ; then 
    echo "ok, NAS IQN available as /dev/${DISKDEV}" 
  else 
    echo "NAS IQN NOT available as /dev/${DISKDEV}."
    echo "  Maybe mounted as different device."
    echo "    check with  fdisk -l  or  dmesg."
    exit 1 
  fi

  if [[ ${JOBTODO} = "mount" ]]  ; then
    # start decrypting:
    cryptsetup luksOpen /dev/${DISKDEV} ${CRYPTNAS}

    # mount:
    mount /dev/mapper/${CRYPTNAS} ${MNTNAS}

    df -h ${MNTNAS}
  else
    echo "... use /dev/${DISKDEV} for copying encrypted data." 
  fi 

fi ###########################################################################




if [[ ${JOBTODO} = "umount" ]] ; then ######################################## if umount... ###

  # Unmount NAS:
  umount ${MNTNAS}
  cryptsetup luksClose ${CRYPTNAS}

  # "logout" from iSCSI:
  iscsiadm -m node --targetname "${TARGETNAME}" --portal "${PORTAL}" --logout
  iscsiadm -m discovery --portal "${PORTAL}" --op=delete

fi ###########################################################################
##############################################################################



