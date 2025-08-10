#!/bin/bash
SRCDIR="/home/data/nobackup/"
DESTDIR="/media/fk/86b1e19a-0617-424c-987b-7d46d545b41d/data/mlc05/nobackup/"
INFODIR="/root/logs/backup_infos"
 

# ===================================================================
function checkIfDirsExist()
{
    if [ ! -e $SRCDIR ] ; then
      echo SRCDIR $SRCDIR does not exist
      exit
    fi
    if [ ! -e $DESTDIR ] ;then
      echo DESTDIR $DESTDIR does not exist
      echo "    bash ./020_mount_local_bakhome.sh mount" 
      exit
    fi
}





# ===================================================================
function cpNobackup()
{
  echo "time rsync -avP --delete $SRCDIR $DESTDIR"
  time rsync -avP --delete $SRCDIR $DESTDIR 
}




# ===================================================================
function showDiskfree()
{
  for dest_dir in $DESTDIR; do 
    if [ -e $dest_dir ] ; then
      df -h $dest_dir | head -n 1
      break
    fi
  done
  for dest_dir in $DESTDIR; do
    if [ -e $dest_dir ] ; then
      df -h $dest_dir | head -n 2 | tail -n 1 
    fi
  done
}


# ===================================================================
# ===================================================================
# ===================================================================
echo "--- checking dirs... ------------------------------------------------"
checkIfDirsExist
echo "====================================================================="


echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"


echo "---------------------------------------------------------------------"
echo "$(date +%Y%m%d_%H%M%S) $DESTDIRS start_of_nobackup $0" >> $INFODIR/last_nobackup.txt
cpNobackup
echo "$(date +%Y%m%d_%H%M%S) $DESTDIRS end_of_nobackup   $0" >> $INFODIR/last_nobackup.txt
echo "---------------------------------------------------------------------"


echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"

date

echo "====================================================================="
echo "--- next: please umount and close the encryption --------------------"
echo "      020_mount_local_bakhome.sh umount"
echo "---------------------------------------------------------------------"


