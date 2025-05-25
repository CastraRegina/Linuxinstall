#!/bin/bash
# This scripts checks for duplicate snapshots of the mountpoint-of-btrfs-volume and removes them.


# Usage: ./020_removeSnapshotDuplicates.sh <mountpoint-of-btrfs-volume>
# Example: ./020_removeSnapshotDuplicates.sh /mnt/tinyraid1/

# Check if the directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <mountpoint-of-btrfs-volume>"
    exit 1
fi
# Mountpoint to check for duplicates
MOUNTPOINT="$1"

# remove trailing slash if it is not still root
if [ "$MOUNTPOINT" != "/" ]; then
    MOUNTPOINT="${MOUNTPOINT%/}"
fi

# Check if the mountpoint exists
if [ ! -d "$MOUNTPOINT" ]; then
    echo "Mountpoint $MOUNTPOINT does not exist."
    exit 1
fi

# Check if mountpoint contains snapshots
# use btrfs subvolumes list to check for snapshots
SNAPSHOTS=$(btrfs subvolume list "$MOUNTPOINT" | grep -E 'snapshot' | awk '{print $9}')
if [ -z "$SNAPSHOTS" ]; then
    echo "No snapshots found in $MOUNTPOINT."
    exit 0
fi

# Print number of snapshots
echo "Found $(echo "$SNAPSHOTS" | wc -l) snapshots in $MOUNTPOINT."

# Sort the snapshots and store them in an array
readarray -t SNAPSHOT_ARRAY < <(echo "$SNAPSHOTS" | sort)

# Check if there are at least 2 snapshots to compare
if [ ${#SNAPSHOT_ARRAY[@]} -lt 2 ]; then
    echo "Not enough snapshots to compare."
    exit 0
fi

# Iterate over the sorted array, skipping the first snapshot
# Start comparing from the second snapshot
# and keep the first one as the previous snapshot
PREVIOUS_SNAPSHOT="${SNAPSHOT_ARRAY[0]}"
for ((i=1; i<${#SNAPSHOT_ARRAY[@]}; i++)); do
    SNAPSHOT="${SNAPSHOT_ARRAY[$i]}"
    echo -n "Checking $SNAPSHOT against $PREVIOUS_SNAPSHOT --->" 1>&2
    
    DIFF=$(diff -qr --exclude "snapshots" "$MOUNTPOINT/$SNAPSHOT" "$MOUNTPOINT/$PREVIOUS_SNAPSHOT")
    
    # Check if the diff is empty
    if [ -z "$DIFF" ]; then 
        # Remove the duplicate snapshot
        echo " remove $SNAPSHOT"
        btrfs subvolume delete "$MOUNTPOINT/$SNAPSHOT"
    else
        # keep the snapshot
        echo "        keep $SNAPSHOT"
        PREVIOUS_SNAPSHOT="$SNAPSHOT"
    fi

done

