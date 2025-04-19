#!/bin/bash
# This scripts checks for duplicate snapshots of the mountpoint-of-btrfs-volume and removes them.


# Usage: ./020_removeSnapshotDuplicates.sh <mountpoint-of-btrfs-volume>
# Check if the directory is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <mountpoint-of-btrfs-volume>"
    exit 1
fi
# Mountpoint to check for duplicates
MOUNTPOINT="$1"

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

#print number of snapshots
echo "Found $(echo "$SNAPSHOTS" | wc -l) snapshots in $MOUNTPOINT."

# Print the list of snapshots
echo "Snapshots:"
echo "$SNAPSHOTS"

# iterate over the snapshots, sorted by date
for SNAPSHOT in $(echo "$SNAPSHOTS" | sort ); do
    # if it is the first snapshot, skip it
    if [ "$SNAPSHOT" == "$(echo "$SNAPSHOTS" | head -n 1)" ]; then
        continue
    fi
    # Compare the current snapshot with the previous one
    PREVIOUS_SNAPSHOT=$(echo "$SNAPSHOTS" | grep -B 1 "$SNAPSHOT" | head -n 1)
    # Check if the current snapshot is a duplicate of the previous one
    echo "Checking $SNAPSHOT against $PREVIOUS_SNAPSHOT" 1>&2    
done

