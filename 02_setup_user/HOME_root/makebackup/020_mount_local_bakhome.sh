#!/bin/bash

# encrypted partition given by UUID - see also:
#   /etc/fstab  /etc/crypttab  /etc/security/pam_mount.conf.xml 
export UUID="0fc8cdf8-59c1-4839-91c2-34ad2f20302d"
export CRYPT_MAP="crypt_bakhome"
export MOUNTPOINT="/mnt/bakhome"

# ----------------------------------------------------------------------------
# if ${MOUNTPOINT} path does not exist, then create it
if ! [ -d ${MOUNTPOINT} ] ; then
  mkdir -p ${MOUNTPOINT}
fi

# ----------------------------------------------------------------------------
# check number of arguments and the argument itself:
if [[ $# -ne 1 ]] || ! ( [[ $1 = "mount" ]] || [[ $1 = "mountenc" ]] || [[ $1 = "umount" ]] ) ; then
  echo " $0 error: one argument needed: either 'mountenc', 'mount' or 'umount'" 
  echo "     mountenc : \"mounts\" only the encrypted partition, i.e. asks for password to decrypt"  
  echo "     mount    : does \"mountenc\" and mounts at mountpoint"
  echo "     umount   : closes and unmounts the decrypted share"
  echo " Execute as root!!!"
  exit 1
fi

export JOBTODO=$1
# ----------------------------------------------------------------------------





##############################################################################
if [[ ${JOBTODO} = "mount" ]] || [[ ${JOBTODO} = "mountenc" ]] ; then 

# start decrypting:
  cryptsetup luksOpen /dev/disk/by-uuid/${UUID} ${CRYPT_MAP}

  if [[ ${JOBTODO} = "mount" ]]  ; then
    # mount:
    mount /dev/mapper/${CRYPT_MAP} ${MOUNTPOINT}
  fi 
  
  df -h ${MOUNTPOINT}

fi
##############################################################################




##############################################################################
if [[ ${JOBTODO} = "umount" ]] ; then 

  umount ${MOUNTPOINT}
  cryptsetup luksClose ${CRYPT_MAP}

fi
##############################################################################



