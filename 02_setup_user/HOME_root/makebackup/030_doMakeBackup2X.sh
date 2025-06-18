#!/bin/bash

# Check for exactly two arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <target: bakhome|lanas01|usbhdd> <scope: system|home>"
    exit 1
fi

TARGET="$1"
SCOPE="$2"

# Validate target
if [[ "$TARGET" != "bakhome" && "$TARGET" != "lanas01" && "$TARGET" != "usbhdd" ]]; then
    echo "Error: target must be one of: bakhome, lanas01, usbhdd"
    exit 1
fi

# Validate scope
if [[ "$SCOPE" != "system" && "$SCOPE" != "home" ]]; then
    echo "Error: scope must be one of: system, home"
    exit 1
fi


# =============================================================================
# Section for target
if [ "$TARGET" = "bakhome" ]; then
    echo "Selected target: bakhome"
    DESTDIRS=(
      "/mnt/bakhome/data/mlc05/backup"
    )
    SNAPDIRS=(
      "/mnt/bakhome"
    )
    # ${SNAPDIR}/data --> ${SNAPDIR}/snapshots/snap_YYYYMMDD_hhmmss
    # create subvolume ${SNAPDIR}/data first:
    #     btrfs subvolume create ${SNAPDIR}/data
elif [ "$TARGET" = "lanas01" ]; then
    echo "Selected target: lanas01"
    DESTDIRS=(
      "/mnt/lanas01_bakmlc5/data/mlc05/backup"
    )
    SNAPDIRS=(
      "/mnt/lanas01_bakmlc5"
    )
else
    echo "Selected target: usbhdd"
    DESTDIRS=(
      "/media/fk/6f99a555-c04a-4f2b-83cb-97a27de80f06/data/mlc05/backup"
      "/media/fk/86b1e19a-0617-424c-987b-7d46d545b41d/data/mlc05/backup"
    )
      #"/data/nobackup/backup_test/mlc05/backup"
    SNAPDIRS=(
      "/media/fk/6f99a555-c04a-4f2b-83cb-97a27de80f06"
      "/media/fk/86b1e19a-0617-424c-987b-7d46d545b41d"
    )
      #"/data/nobackup/backup_test"
fi
for i in "${!DESTDIRS[@]}"; do
  DESTDIRS[$i]="${DESTDIRS[$i]}_${SCOPE}"
done

# Section for scope
if [ "$SCOPE" = "system" ]; then
    echo "Selected scope:  system"
    SRCDIRS=("/boot" "/etc"         "/opt"         "/usr" "/var")
else
    echo "Selected scope:  home"
    SRCDIRS=(               "/home"        "/root"              )
fi
# =============================================================================


INFODIR="/root/logs/backup_infos"
NOBACKUPDIRS=(
  "/bin"
  "/data"
  "/dev"
  "/home/data/nobackup"
  "/home/snapshots"
  "/lib"
  "/lib32"
  "/lib64"
  "/libx32"
  "/lost+found"
  "/media"
  "/mnt"
  "/proc"
  "/run"
  "/sbin"
  "/srv"
  "/sys"
  "/tmp"
  "/var/crash"
  "/var/lock"
  "/var/metrics"
  "/var/run"
  "/var/tmp"
)

echo "------------------------------------------------------------------------"
echo "SRCDIRS:      ${SRCDIRS[*]}"
echo "NOBACKUPDIRS: ${NOBACKUPDIRS[*]}"
echo "DESTDIRS:     ${DESTDIRS[*]}"
echo "SNAPDIRS:     ${SNAPDIRS[*]}"
echo "INFODIR:      ${INFODIR}"
echo "------------------------------------------------------------------------"
echo
echo

# =============================================================================
# =============================================================================
echo "--- checking directories... --------------------------------------------"
for i in "${SRCDIRS[@]}"; do
  if [ ! -e "$i" ] ;then
    echo "SRCDIR $i does not exist"
    exit
  fi
done


for i in "${NOBACKUPDIRS[@]}"; do
  if [ ! -e "$i" ] ;then
    echo "NOBACKUPDIR $i does not exist"
    exit
  fi
done


if [ ! -e "$INFODIR" ] ;then
  echo "INFODIR $INFODIR does not exist"
  exit
fi


EXISTINGDESTDIRS=()
for i in "${DESTDIRS[@]}"; do
  if [ -e "$i" ] ;then
    EXISTINGDESTDIRS+=("$i")
  else
    echo "DESTDIR $i does not exist"
    echo "    bash ./020_mount_local_bakhome.sh mount" 
  fi
done
DESTDIRS=("${EXISTINGDESTDIRS[@]}")


if [ ${#DESTDIRS[@]} -eq 0 ] ;then
  echo "No DESTDIRS available, exiting"
  exit
fi
echo "------------------------------------------------------------------------"
# ===================================================================



function saveInfo()
{
  dpkg --get-selections "*" > "$INFODIR/debian_package_selections.txt"

  backup_time=$(date +%Y%m%d_%H%M%S)

  echo "$backup_time ---------------------------------------"    >> "$INFODIR/last_backup_mnt.txt"
  ls -ld /mnt/*                                                  >> "$INFODIR/last_backup_mnt.txt"
  echo "-------------------------------------------------------" >> "$INFODIR/last_backup_mnt.txt"

  echo "$backup_time ---------------------------------------"    >> "$INFODIR/last_backup_mount.txt"
  mount                                                          >> "$INFODIR/last_backup_mount.txt"
  echo "-------------------------------------------------------" >> "$INFODIR/last_backup_mount.txt"

  echo "$backup_time ---------------------------------------"    >> "$INFODIR/last_backup_df.txt"
  df -h                                                          >> "$INFODIR/last_backup_df.txt"
  echo "-------------------------------------------------------" >> "$INFODIR/last_backup_df.txt"

  echo "$backup_time ---------------------------------------"    >> "$INFODIR/last_backup_blkid.txt"
  blkid                                                          >> "$INFODIR/last_backup_blkid.txt"
  echo "-------------------------------------------------------" >> "$INFODIR/last_backup_blkid.txt"

  echo "$backup_time ---------------------------------------"    >> "$INFODIR/last_backup_btrfs.txt"
  btrfs filesystem show                                          >> "$INFODIR/last_backup_btrfs.txt"
  echo "-------------------------------------------------------" >> "$INFODIR/last_backup_btrfs.txt"
}

# ===================================================================
function makeBackupTo()
{
  dest_dir="$1"

  # build up include directories: -----------------------------------
  include_dirs=()
  for i in "${SRCDIRS[@]}"; do
    include_dirs+=( "--include" "$i" )
  done
  # -----------------------------------------------------------------

  # build up exclude directories: -----------------------------------
  exclude_dirs=( "--exclude" "$dest_dir" )
  for i in "${NOBACKUPDIRS[@]}"; do
    exclude_dirs+=( "--exclude" "$i" )
  done
  # -----------------------------------------------------------------

  echo "rdiff-backup --new --api-version 201 backup  ${exclude_dirs[@]}   ${include_dirs[@]}  --exclude '**' /  $dest_dir"
  time  rdiff-backup --new --api-version 201 backup "${exclude_dirs[@]}" "${include_dirs[@]}" --exclude '**' / "$dest_dir" &
}

# ===================================================================
function makeSnapshots()
{
  snap_time=$(date +%Y%m%d_%H%M%S)
  for i in "${SNAPDIRS[@]}"; do
    if [ ! -e "${i}/data" ] || [ ! -e "${i}/snapshots" ] ; then
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
  for dest_dir in "${DESTDIRS[@]}"; do 
    if [ -e "$dest_dir" ] ; then
      df -h "$dest_dir" | head -n 1
      break
    fi
  done
  for dest_dir in "${DESTDIRS[@]}"; do
    if [ -e "$dest_dir" ] ; then
      df -h "$dest_dir" | head -n 2 | tail -n 1 
    fi
  done
}

# ===================================================================
function cleanUsersHomes()
{
  echo "--- cleaning users' home directories... ----------------------------"
  for i in /home/*; do
    if [ -d "$i" ]; then
      # Check if the directory is a user home directory
      if getent passwd "$(basename "$i")" > /dev/null 2>&1 ; then
        echo "Cleaning home directory (and more...): $i"
        # Remove .local/share/Trash
        rm -rf "${i}"/.local/share/Trash
        # Remove .thumbnails
        rm -rf "${i}"/.cache/thumbnails/*
        rm -rf "${i}"/.thumbnails/*
        # Remove .cache/pip
        rm -rf "${i}"/.cache/pip/*
        # Firefox
        rm -rf "${i}"/.cache/mozilla/firefox/*/cache2/*
        rm -rf "${i}"/.mozilla/firefox/*/cache2/*
        # Chrome/Chromium
        rm -rf "${i}"/.cache/google-chrome/*/Cache/*
        rm -rf "${i}"/.cache/chromium/*/Cache/*
      else
        echo "Skipping non-user directory: $i"
      fi
    fi
  done
  echo "---------------------------------------------------------------------"
}
# ===================================================================
# ===================================================================
# ===================================================================
echo "---------------------------------------------------------------------"
makeSnapshots
echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
cleanUsersHomes
echo "---------------------------------------------------------------------"

echo "--- apt-get clean... ------------------------------------------------"
sudo apt-get clean
sudo apt clean
sudo apt autoclean
echo "---------------------------------------------------------------------"

echo "--- saving infos... -------------------------------------------------"
saveInfo
echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
echo "$(date +%Y%m%d_%H%M%S) ${DESTDIRS[*]} start_of_backup $0" >> "$INFODIR/last_backup.txt"
for dest_dir in "${DESTDIRS[@]}"; do
  if [ -e "$dest_dir" ] ; then
    makeBackupTo "$dest_dir"    
  else
    echo "DESTDIR $dest_dir does not exist"
  fi
  echo
done
sleep 2s

wait
echo "$(date +%Y%m%d_%H%M%S) ${DESTDIRS[*]} end_of_backup   $0" >> "$INFODIR/last_backup.txt"
echo "---------------------------------------------------------------------"

echo "---------------------------------------------------------------------"
showDiskfree
echo "---------------------------------------------------------------------"

date

echo "====================================================================="
echo "--- next: please umount and close the encryption --------------------"
echo "      020_mount_local_bakhome.sh umount"
echo "      handle snapshots:"
echo "        btrfs subvolume list ${SNAPDIR}"
echo "        btrfs subvolume delete ${SNAPDIR}/snapshots/snap_20231022_194647"
echo "      handle rdiff-backup:"
echo "        rdiff-backup --list-increments ${SNAPDIR}/data/mlc05/backup"
echo "        rdiff-backup --force --remove-older-than 100D ${SNAPDIR}/data/mlc05/backup"
echo "---------------------------------------------------------------------"


