#!/bin/bash
SRCDIR="/home/data/nobackup/"
DESTDIR="/mnt/bakhome/data/mlc05/nobackup/"
 

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
cpNobackup
echo "---------------------------------------------------------------------"


echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"

date

echo "====================================================================="
echo "--- next: please umount and close the encryption --------------------"
echo "      020_mount_local_bakhome.sh umount"
echo "---------------------------------------------------------------------"


