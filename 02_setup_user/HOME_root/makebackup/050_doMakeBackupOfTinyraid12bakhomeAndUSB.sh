#!/bin/bash

SRCDIR="/mnt/tinyraid1"
SNAPSHOTDIR="/mnt/tinyraid1/snapshots"
DESTDIRS="/mnt/bakhome/data/mlc05/backup_tinyraid1"
DESTDIRS="${DESTDIRS} /media/fk/eaf1e9fa-e085-4ed6-87ce-bd5f924cdf25/data"
DESTDIRS="${DESTDIRS} /media/fk/6153ad40-0940-4118-9562-5a17286a5591/data"
DESTDIRS="${DESTDIRS} /media/fk/225393ec-cae0-433a-ac18-749dcfe9e980/data"
DESTDIRS="${DESTDIRS} /media/fk/7e8a091f-01fa-428f-8c84-2924bfe71956/data"

for DESTDIR in ${DESTDIRS} ; do
  if [ -e ${DESTDIR} ] ; then
    df -h ${DESTDIR}
    time rdiff-backup --exclude ${SNAPSHOTDIR} --include ${SRCDIR} --exclude '**' / ${DESTDIR}
    df -h ${DESTDIR}
    echo "diff -rq ${SRCDIR} ${DESTDIR}${SRCDIR}"
    diff -rq ${SRCDIR} ${DESTDIR}${SRCDIR}
    echo "==========================================================================="
  fi
done

