#!/bin/bash

SUBVOLUME="/home"
SNAPSHOT_DIR="/home/snapshots"


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
  echo "For today snapshot already exists, ${snapshot_name_day}"
else
  btrfs subvolume snapshot -r ${SUBVOLUME} ${snapshot_name_day_time} 
fi

btrfs subvolume list ${SUBVOLUME}

