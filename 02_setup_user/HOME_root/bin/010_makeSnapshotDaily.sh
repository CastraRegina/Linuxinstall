#!/bin/bash

# example for arguments $1 and $2:
# example call: 010_makeSnapshotDaily.sh /home /home/snapshots 
SUBVOLUME="/home"
SNAPSHOT_DIR="/home/snapshots"

if [ "$#" -ne 2 ]; then
  echo "Illegal number of parameters"
  exit 1
fi

# extract values from arguments:
SUBVOLUME="$1"
SNAPSHOT_DIR="$2"

snapshot_day=$(date +%Y%m%d)
snapshot_time=$(date +%H%M%S)
snapshot_name_day=${SNAPSHOT_DIR}/snapshot_${snapshot_day}
snapshot_name_day_time=${snapshot_name_day}_${snapshot_time}


if [ ! -e ${SUBVOLUME} ] ; then
  echo "Error: dir ${SUBVOLUME} does not exist"
  exit 1
fi
if [ ! -e ${SNAPSHOT_DIR} ] ; then
  echo "Error: dir ${SNAPSHOT_DIR} does not exist"
  exit 1
fi


# check if for today already a snapshot exists
ls -d1 ${snapshot_name_day}* >/dev/null 2>&1
if [ $? -eq 0 ] ; then
  echo "For today snapshot already exists: ${snapshot_name_day}"
else
  btrfs subvolume snapshot -r ${SUBVOLUME} ${snapshot_name_day_time} 
fi

btrfs subvolume list ${SUBVOLUME}

