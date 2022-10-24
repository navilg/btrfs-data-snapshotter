# btrfs-data-snapshotter
Simple script to take snapshot and restore btrfs subvolumes

# Requirements

- A btrfs filesystem
- btrfs tool, Run `which btrfs` to check
- anacron, Run `which anacron` to check
- bash shell
- Root/sudo permission

## How to use it

- Rename this file to your wish

```
cp btrsnap.sh btrsnap_data_daily.sh
chmod +x btrsnap_data_daily.sh
```

- Update configurations

Configurations are written in same script file between lines:

```
### BEGINNING OF CONFIGURATIONS ###
configurations...
### END OF CONFIGURATIONS ###
```

```
# Edit the script file
# CONFIGURATIONS are in beginning of the file.
# Change env var as required.
vi btrsnap_data_daily.sh
```

- Create target directory

Create target directory set in configuration

```
mkdir /mount/path/of/btrfs/filesystem/<BTRFS_TARGET>
```

- Add cronjob


```
sudo crontab -e
```

Add below entries, as required.

```
@daily /path/to/this/script/btrsnap_data_daily.sh
# @weekly /path/to/this/script/btrsnap_data_weekly.sh
# @monthly /path/to/this/script/btrsnap_data2_monthly.sh
```

## How to restore

To restore from a snapshot, Use below steps:

List all the snapshots:

```
sudo btrfs subvolume list <BTRFS_FS_MOUNTPATH>
```

BTRFS_FS_MOUNTPATH is your btrfs filesystem. All the subvolumes under <BTRFS_TARGET> are the snapshots. Choose the snapshots as per the date and time (snapshot name is suffixed with date and time in format YYYYMMDDHHMMSS).

1. To restore a specific file

```
cp <SNAPSHOT_SUBVOLUME>/path/to/file/filename /path/to/restore/directory/filename
```

2. To restore an entire directory

```
cp -r <SNAPSHOT_SUBVOLUME>/path/to/file/directoryname /path/to/restore/directory/directoryname
```

3. If an entire subvolume is deleted accidently

```
# Create subvolume
sudo btrfs subvolume create <BTRFS_FS_MOUNTPATH>/<SUBVOLUME_NAME>

# Copy entire snapshot to created subvolume
cp -rT <SNAPSHOT_SUBVOLUME> <BTRFS_FS_MOUNTPATH>/<SUBVOLUME_NAME>
```

OR, Recommended way,

```
# Create snapshot of a snapshot
sudo btrfs subvolume snapshot <SNAPSHOT_SUBVOLUME> <BTRFS_FS_MOUNTPATH>/<SUBVOLUME_NAME>
```
