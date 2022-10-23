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
