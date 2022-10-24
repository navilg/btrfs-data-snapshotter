#!/usr/bin/env bash

### BEGINNING OF CONFIGURATIONS ###

# Create snapshot of <BTRFS_FS_MOUNTPATH>/<BTRFS_SUBVOL>. Call it <BTRFS_SUBVOL-BTRFS_SNAPSHOT_IDENTIFIER-YYYYMMDDHHMMSS>
# and place it in <BTRFS_FS_MOUNTPATH>/<BTRFS_TARGET>/<BTRFS_SUBVOL> directory.

BTRFS_SNAPSHOT_IDENTIFIER=daily         # Unique label/identifier for snapshots.
BTRFS_FS_MOUNTPATH=/media/navi/Data     # Absolute mount path of BTRFS filesystem
BTRFS_SUBVOLS=Documents,Storage         # Comma separated subvolumes
BTRFS_TARGET=.btrfs-snapshots           # Path under filesystem mountpath where snapshots will be stored, must be created manually.
BTRFS_RETAIN_SNAP_NUMBER=5              # Number of snapsshots to retain

### END OF CONFIGURATIONS ###

# Check if run as root #

if [ $UID -ne 0 ]; then
    echo "This script must be run as root or with sudo privilege."
    exit 1
fi

# Generate 6 digit unique id

unique_id=$(cat /dev/urandom | head -10 | tr -dc [:digit:] | cut -c1-6)

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

for BTRFS_SUBVOL in $(echo ${BTRFS_SUBVOLS} | sed "s/,/ /g"); do

    if [ -z "${BTRFS_SUBVOL}" ]; then
        continue
    fi

    btrfs subvolume list /media/navi/Data/ | grep -wE ${BTRFS_SUBVOL}/${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-[0-9]{14} | tr -s " " | rev | cut -d " " -f 1 | rev | sort -n | tail -n +$(expr ${BTRFS_RETAIN_SNAP_NUMBER} + 1) | tee "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"

    while read -r line; do
        btrfs subvolume delete "/${BTRFS_FS_MOUNTPATH}/${line}"
        exitCode=$?
        if [ $exitCode -ne 0 ]; then
            echo "Failed to delete snapshot - "/${BTRFS_FS_MOUNTPATH}/${line}""
        fi
    done < "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"

    rm "/tmp/expired_btrfs-${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-${unique_id}"
done

echo
echo "Expired snapshots deleted."
echo
echo "Available snapshots:"
echo "--------------------"
btrfs subvolume list /media/navi/Data/ | grep -wE ${BTRFS_SUBVOL}/${BTRFS_SUBVOL}-${BTRFS_SNAPSHOT_IDENTIFIER}-[0-9]{14} | tr -s " " | rev | cut -d " " -f 1 | rev | sort -n -r
echo
echo "DONE"
echo