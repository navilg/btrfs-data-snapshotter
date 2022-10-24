#!/usr/bin/env bash

### BEGINNING OF CONFIGURATIONS ###

# Create snapshot of <BTRFS_FS_MOUNTPATH>/<BTRFS_SUBVOL>. Call it <BTRFS_SUBVOL-BTRFS_SNAPSHOT_IDENTIFIER-YYYYMMDDHHMMSS>
# and place it in <BTRFS_FS_MOUNTPATH>/<BTRFS_TARGET>/<BTRFS_SUBVOL> directory.

BTRFS_SNAPSHOT_IDENTIFIER=daily         # Unique label/identifier for snapshots.
BTRFS_FS_MOUNTPATH=/media/navi/Data     # Absolute mount path of BTRFS filesystem
BTRFS_SUBVOLS=Documents,Storage         # Comma separated subvolumes
BTRFS_TARGET=.btrfs-snapshots           # Path under filesystem mountpath where snapshots will be stored, must be created manually.
BTRFS_RETAIN_SNAP_NUMBER=5              # Number of snapsshots to retain.
BTRFS_SNAP_TTL_DAYS=7                   # Number of days for a backup to be retained. This will be considered only when BTRFS_RETAIN_SNAP_NUMBER is fulfilled.

# If BTRFS_RETAIN_SNAP_NUMBER=5 and BTRFS_SNAP_TTL=7d. You have 3 snapshots out of which 2 are more than 8 days old.
# In this case, All 3 snapshots will be retained because number of snapshots is not atleast bare minimum required i.e. 5.

### END OF CONFIGURATIONS ###

# Check if run as root #

if [ $UID -ne 0 ]; then
    echo "This script must be run as root or with sudo privilege."
    exit 1
fi

# Generate 6 digit unique id

unique_id=$(cat /dev/urandom | head -10 | tr -dc [:digit:] | cut -c1-6)

# Duration function

duration() {
    creation_time_unix=$(date -d "$1" +%s)
    current_time_unix=$(date +%s)

    local duration_in_days=$(expr $(expr $current_time_unix - $creation_time_unix) / 86400)
    echo ${duration_in_days}
}

# Create snapshot #

echo "Create snapshots..."
echo

for BTRFS_SUBVOL in $(echo ${BTRFS_SUBVOLS} | sed "s/,/ /g"); do

    if [ -z "${BTRFS_SUBVOL}" ]; then
        continue
    fi

    if [ ! -d "/${BTRFS_FS_MOUNTPATH}/${BTRFS_TARGET}/${BTRFS_SUBVOL}" ]; then
        mkdir "/${BTRFS_FS_MOUNTPATH}/${BTRFS_TARGET}/${BTRFS_SUBVOL}"
    fi

    btrfs subvolume snapshot -r "/${BTRFS_FS_MOUNTPATH}/${BTRFS_SUBVOL}" "/${BTRFS_FS_MOUNTPATH}/${BTRFS_TARGET}/${BTRFS_SUBVOL}/${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-$(date +%Y%m%d%H%M%S)"
    exitCode=$?

    if [ $exitCode -ne 0 ]; then
        echo "Failed to create snapshot of "/${BTRFS_FS_MOUNTPATH}/${BTRFS_SUBVOL}""
    fi
done

echo
echo "Snapshots created."
echo

# Delete expired snapshot #

echo "Delete expired snapshot..."
echo
count=0
for BTRFS_SUBVOL in $(echo ${BTRFS_SUBVOLS} | sed "s/,/ /g"); do

    if [ -z "${BTRFS_SUBVOL}" ]; then
        continue
    fi

    btrfs subvolume list "/${BTRFS_FS_MOUNTPATH}/" | grep -wE ${BTRFS_SUBVOL}/${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-[0-9]{14} | tr -s " " | rev | cut -d " " -f 1 | rev | sort -nr | tail -n +$(expr ${BTRFS_RETAIN_SNAP_NUMBER} + 1) > "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"
    while read -r line; do
        creation_time=$(sudo btrfs subvolume show -h "/${BTRFS_FS_MOUNTPATH}/${line}" | grep "Creation time" | cut -d ":" -f 2- | tr -d "\t" | sed 's/^[[:space:]]*//')
        duration_in_days=$(duration "${creation_time}")
        if [ ${duration_in_days} -gt ${BTRFS_SNAP_TTL_DAYS} ]; then
            btrfs subvolume delete "/${BTRFS_FS_MOUNTPATH}/${line}"
            exitCode=$?
            if [ $exitCode -ne 0 ]; then
                echo "Failed to delete snapshot - "/${BTRFS_FS_MOUNTPATH}/${line}""
            else
                count=$(expr ${count} + 1)
            fi
        fi
    done < "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"

    rm "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"
done

echo
echo "${count} expired snapshots deleted."
echo
echo "DONE"
echo