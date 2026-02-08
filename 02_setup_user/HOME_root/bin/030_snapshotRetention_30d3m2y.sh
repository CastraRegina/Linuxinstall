#!/usr/bin/env bash

###############################################################################
# Btrfs Snapshot Retention Script
#
# Usage:
#   ./btrfs-retention.sh <snapshot_dir> [--apply]
#
# Example:
#   ./btrfs-retention.sh /home/snapshots
#   ./btrfs-retention.sh /home/snapshots --apply
#
# Snapshots must follow this naming convention:
#   snapshot_YYYYMMDD_hhmmss
#
# Retention policy:
#
# 1. Snapshots from the last 30 days:
#    -> keep all
#
# 2. Snapshots from last 3 months (excluding last 30 days):
#    -> keep first snapshot per ISO week
#
# 3. Snapshots from last 2 years (excluding last 3 months):
#    -> keep first snapshot per month
#
# 4. Snapshots older than 2 years:
#    -> keep first snapshot per quarter
#
# Default mode is DRY-RUN (no deletion).
# Use --apply to actually delete snapshots.
#
###############################################################################

set -euo pipefail

############################
# Argument parsing
############################

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <snapshot_dir> [--apply]"
    exit 1
fi

SNAPSHOT_DIR="$1"
APPLY_MODE=false

if [[ "${2:-}" == "--apply" ]]; then
    APPLY_MODE=true
fi

if [[ ! -d "$SNAPSHOT_DIR" ]]; then
    echo "Error: Snapshot directory does not exist: $SNAPSHOT_DIR"
    exit 1
fi

############################
# Configuration
############################

SNAPSHOT_PREFIX="snapshot_"

############################
# Date thresholds
############################

NOW_EPOCH=$(date +%s)
THIRTY_DAYS_AGO=$(date -d "30 days ago" +%s)
THREE_MONTHS_AGO=$(date -d "3 months ago" +%s)
TWO_YEARS_AGO=$(date -d "2 years ago" +%s)

############################
# Collect snapshots
############################

declare -A SNAP_EPOCH
declare -A SNAP_RULE
declare -A SNAP_KEEP

SNAPSHOTS=()

while IFS= read -r -d '' dir; do
    name=$(basename "$dir")

    if [[ $name =~ ^${SNAPSHOT_PREFIX}([0-9]{8})_([0-9]{6})$ ]]; then
        date_part="${BASH_REMATCH[1]}"
        time_part="${BASH_REMATCH[2]}"

        epoch=$(date -d "${date_part:0:4}-${date_part:4:2}-${date_part:6:2} \
                         ${time_part:0:2}:${time_part:2:2}:${time_part:4:2}" +%s)

        SNAPSHOTS+=("$name")
        SNAP_EPOCH["$name"]=$epoch
    fi
done < <(find "$SNAPSHOT_DIR" -maxdepth 1 -mindepth 1 -type d -name "${SNAPSHOT_PREFIX}*" -print0)

# Sort snapshots chronologically
IFS=$'\n' SNAPSHOTS_SORTED=($(for s in "${SNAPSHOTS[@]}"; do
    echo "${SNAP_EPOCH[$s]}|$s"
done | sort -n | cut -d'|' -f2))
unset IFS

############################
# Helper maps for retention
############################

declare -A WEEK_FIRST
declare -A MONTH_FIRST
declare -A QUARTER_FIRST

############################
# Determine retention
############################

for snap in "${SNAPSHOTS_SORTED[@]}"; do
    epoch=${SNAP_EPOCH[$snap]}

    if (( epoch >= THIRTY_DAYS_AGO )); then
        SNAP_KEEP["$snap"]=1
        SNAP_RULE["$snap"]="within 30 days"
        continue
    fi

    if (( epoch >= THREE_MONTHS_AGO )); then
        week=$(date -d "@$epoch" +%G-%V)
        if [[ -z "${WEEK_FIRST[$week]:-}" ]]; then
            WEEK_FIRST[$week]=$snap
            SNAP_KEEP["$snap"]=1
            SNAP_RULE["$snap"]="weekly retention"
        else
            SNAP_KEEP["$snap"]=0
            SNAP_RULE["$snap"]="weekly retention (not first of week)"
        fi
        continue
    fi

    if (( epoch >= TWO_YEARS_AGO )); then
        month=$(date -d "@$epoch" +%Y-%m)
        if [[ -z "${MONTH_FIRST[$month]:-}" ]]; then
            MONTH_FIRST[$month]=$snap
            SNAP_KEEP["$snap"]=1
            SNAP_RULE["$snap"]="monthly retention"
        else
            SNAP_KEEP["$snap"]=0
            SNAP_RULE["$snap"]="monthly retention (not first of month)"
        fi
        continue
    fi

    # Older than 2 years → quarterly
    year=$(date -d "@$epoch" +%Y)
    month=$(date -d "@$epoch" +%m)
    quarter=$(( (10#$month - 1) / 3 + 1 ))
    key="${year}-Q${quarter}"

    if [[ -z "${QUARTER_FIRST[$key]:-}" ]]; then
        QUARTER_FIRST[$key]=$snap
        SNAP_KEEP["$snap"]=1
        SNAP_RULE["$snap"]="quarterly retention"
    else
        SNAP_KEEP["$snap"]=0
        SNAP_RULE["$snap"]="quarterly retention (not first of quarter)"
    fi
done

############################
# Output and optional deletion
############################

for snap in "${SNAPSHOTS_SORTED[@]}"; do
    rule="${SNAP_RULE[$snap]}"
    path="${SNAPSHOT_DIR}/${snap}"

    if [[ "${SNAP_KEEP[$snap]}" -eq 1 ]]; then
        printf "[KEEP]   %-30s (%s)\n" "$snap" "$rule"
    else
        printf "[DELETE] %-30s (%s)\n" "$snap" "$rule"

        if $APPLY_MODE; then
            btrfs subvolume delete "$path"
        fi
    fi
done

if ! $APPLY_MODE; then
    echo
    echo "Dry-run mode. No snapshots were deleted."
    echo "Run with --apply to perform actual deletions."
fi

