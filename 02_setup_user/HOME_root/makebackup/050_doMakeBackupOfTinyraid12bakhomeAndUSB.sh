#!/bin/bash

SRCDIR="/mnt/tinyraid1"
SNAPSHOTDIR="/mnt/tinyraid1/snapshots"
DESTDIRS=(
  # Local backup destination
  "/mnt/bakhome/data/mlc05/backup_tinyraid1"
  # USBsticks
  "/media/fk/eaf1e9fa-e085-4ed6-87ce-bd5f924cdf25/data"
  "/media/fk/6153ad40-0940-4118-9562-5a17286a5591/data"
  "/media/fk/225393ec-cae0-433a-ac18-749dcfe9e980/data"
  "/media/fk/7e8a091f-01fa-428f-8c84-2924bfe71956/data"
  # USBHDDs
  "/media/fk/069cab59-bb05-4c98-bcda-d45cff2b1ddd/data/mlc05/backup_tinyraid1"
  "/media/fk/86b1e19a-0617-424c-987b-7d46d545b41d/data/mlc05/backup_tinyraid1"
)


echo "==========================================================================="
  echo rdiff-backup info
  rdiff-backup info
echo "==========================================================================="


for DESTDIR in "${DESTDIRS[@]}" ; do
  if [ -d ${DESTDIR} ] ; then
    echo "==========================================================================="
    df -h ${DESTDIR}
    echo "==========================================================================="

    # Using rdiff-backup with --new and --api-version 201 ensures compatibility with the latest API version and enables new features.
    echo "rdiff-backup --new --api-version 201 backup --exclude ${SNAPSHOTDIR} --include ${SRCDIR} --exclude '**' / ${DESTDIR}"
    time  rdiff-backup --new --api-version 201 backup --exclude ${SNAPSHOTDIR} --include ${SRCDIR} --exclude '**' / ${DESTDIR}

    echo "==========================================================================="
    df -h ${DESTDIR}
    echo "==========================================================================="

    echo "==========================================================================="
    echo "diff -rq ${SRCDIR} ${DESTDIR}${SRCDIR}"
    diff -rq ${SRCDIR} ${DESTDIR}${SRCDIR}
    echo "==========================================================================="
  fi
done

