#!/bin/bash
SRCDIRS="/bin /boot /etc /home /lib /lib32 /lib64 /libx32 /root /sbin /usr/local /usr/src /var"
#SRCDIRS="/boot"
NOBACKUPDIRS="/data /dev /home/data/nobackup /media /mnt /opt /proc /run /srv /sys /home/snapshots /tmp /var/run"
DESTDIRS="/mnt/bakhome/data/mlc05/backup"
INFODIR="/root/logs/backup_infos"
SNAPDIRS="/mnt/bakhome"          # ${i}/data --> ${i}/snapshots/snap_YYYYMMDD_hhmmss
                                 # create subvolume ${i}/data first:
                                 #   btrfs subvolume create ${i}/data

 

# ===================================================================
function checkIfDirsExist()
{
  for i in $SRCDIRS; do
    if [ ! -e $i ] ;then
      echo SRCDIR $i does not exist
      exit
    fi
  done
  for i in $NOBACKUPDIRS; do
    if [ ! -e $i ] ;then
      echo NOBACKUPDIR $i does not exist
      exit
    fi
  done
  if [ ! -e $INFODIR ] ;then
    echo INFODIR $INFODIR does not exist
    exit
  fi
  for i in $DESTDIRS; do
    if [ ! -e $i ] ;then
      echo DESTDIR $i does not exist
      echo "    bash ./020_mount_local_bakhome.sh mount" 
    fi
  done
}




# ===================================================================
function saveInfo()
{
  dpkg --get-selections "*" > $INFODIR/debian_package_selections.txt

  backup_time=$(date +%Y%m%d_%H%M%S)

  echo "$backup_time ---------------------------------------"    >> $INFODIR/last_backup_mnt.txt
  ls -ld /mnt/*                                                  >> $INFODIR/last_backup_mnt.txt
  echo "-------------------------------------------------------" >> $INFODIR/last_backup_mnt.txt

  
  echo "$backup_time ---------------------------------------"    >> $INFODIR/last_backup_mount.txt
  mount                                                          >> $INFODIR/last_backup_mount.txt
  echo "-------------------------------------------------------" >> $INFODIR/last_backup_mount.txt

 
  echo "$backup_time ---------------------------------------"    >> $INFODIR/last_backup_df.txt
  df -h                                                          >> $INFODIR/last_backup_df.txt
  echo "-------------------------------------------------------" >> $INFODIR/last_backup_df.txt

 
  echo "$backup_time ---------------------------------------"    >> $INFODIR/last_backup_blkid.txt
  blkid                                                          >> $INFODIR/last_backup_blkid.txt
  echo "-------------------------------------------------------" >> $INFODIR/last_backup_blkid.txt

 
  echo "$backup_time ---------------------------------------"    >> $INFODIR/last_backup_btrfs.txt
  btrfs filesystem show                                          >> $INFODIR/last_backup_btrfs.txt
  echo "-------------------------------------------------------" >> $INFODIR/last_backup_btrfs.txt

}


# ===================================================================
function makeBackupTo()
{
  dest_dir="$1"

  # build up include directories: -----------------------------------
  include_dirs=
  for i in $SRCDIRS; do
    include_dirs="$include_dirs --include ${i} "
  done
  # -----------------------------------------------------------------

  # build up exclude directories: -----------------------------------
  exclude_dirs="--exclude $dest_dir "
  for i in $NOBACKUPDIRS; do
    exclude_dirs="$exclude_dirs --exclude ${i} "
  done
  # -----------------------------------------------------------------

  #echo $include_dirs
  echo "rdiff-backup $exclude_dirs $include_dirs --exclude '**' / $dest_dir"
  ### time  rdiff-backup --force $exclude_dirs $include_dirs --exclude '**' / $dest_dir
  time  rdiff-backup $exclude_dirs $include_dirs --exclude '**' / $dest_dir &
}



# ===================================================================
function makeSnapshots()
{
  # ${i}/data --> ${i}/snapshots/snap_YYYYMMDD-hhmmss
  snap_time=$(date +%Y%m%d_%H%M%S)
  for i in $SNAPDIRS; do
    if [ ! -e ${i}/data  -o  ! -e ${i}/snapshots ] ; then
      echo "SNAPDIR-src ${i}/data  OR  SNAPDIR-dest ${i}/snapshots does not exist"
    else
      snap_source="${i}/data" 
      snap_name="${i}/snapshots/snap_${snap_time}"
      echo "btrfs subvolume snapshot -r ${snap_source} ${snap_name}"
      btrfs subvolume snapshot -r "${snap_source}" "${snap_name}"
    fi
  done
}


# ===================================================================
function showDiskfree()
{
  for dest_dir in $DESTDIRS; do 
    if [ -e $dest_dir ] ; then
      df -h $dest_dir | head -n 1
      break
    fi
  done
  for dest_dir in $DESTDIRS; do
    if [ -e $dest_dir ] ; then
      df -h $dest_dir | head -n 2 | tail -n 1 
    fi
  done
}


# ===================================================================
# ===================================================================
# ===================================================================
echo "--- cleaning packages from cache... ---------------------------------"
apt-get clean
echo "--- checking dirs... ------------------------------------------------"
checkIfDirsExist
echo "====================================================================="


echo "---------------------------------------------------------------------"
makeSnapshots
echo "---------------------------------------------------------------------"

#echo "---------------------------------------------------------------------"
saveInfo    
#echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"


echo "---------------------------------------------------------------------"
echo "$(date +%Y%m%d_%H%M%S) $DESTDIRS start_of_backup $0" >> $INFODIR/last_backup.txt
for dest_dir in $DESTDIRS; do
  if [ -e $dest_dir ] ; then
    makeBackupTo $dest_dir    
  else
    echo DESTDIR $dest_dir does not exist
  fi
  echo
done
sleep 2s

wait
echo "$(date +%Y%m%d_%H%M%S) $DESTDIRS end_of_backup   $0" >> $INFODIR/last_backup.txt
echo "---------------------------------------------------------------------"


echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"

date

for SNAPDIR in ${SNAPDIRS} ; do echo -n "" ; done
echo "====================================================================="
echo "--- next: please umount and close the encryption --------------------"
echo "      020_mount_local_bakhome.sh umount"
echo "      handle snapshots:"
echo "        btrfs subvolume list ${SNAPDIR}"
echo "        btrfs subvolume delete ${SNAPDIR}/snapshots/snap_20231022_194647"
echo "      handle rdiff-backup:"
echo "        rdiff-backup --list-increments ${SNAPDIR}/data/mlc05/backup"
echo "        rdiff-backup --force --remove-older-than 100B ${SNAPDIR}/data/mlc05/backup"
echo "---------------------------------------------------------------------"


