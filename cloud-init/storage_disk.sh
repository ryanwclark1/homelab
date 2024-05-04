
BLK_ID=/dev/sdb
MOUNT_POINT=/var/lib/longhorn

# sudo apt install parted
echo 'label: gpt' | sudo sfdisk /dev/sdb
echo ',,L' | sudo sfdisk /dev/sdb
sudo mkfs.ext4 -F /dev/sdb1
PART_UUID=$(sudo blkid | grep $BLK_ID | rev | cut -d ' ' -f -1 | tr -d '[:alpha:]' | rev)
# sudo blkid | grep $BLK_ID | cut -d " " -f 3- -
sudo mkdir -p $MOUNT_POINT
echo "$PART_UUID $MOUNT_POINT ext4 defaults 0 2" | sudo tee -a /etc/fstab
