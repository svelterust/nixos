# nixos

To install, set up your partitions:

```bash
sudo -i
lsblk
cfdisk <disk>
mkfs.ext4 -L nixos <partition>
mount <partition> /mnt
```

Then run following commands:

```bash
nixos-generate-config --root /mnt
curl https://raw.githubusercontent.com/knarkzel/nixos/master/configuration.nix -o /mnt/etc/nixos/configuration.nix
nano /mnt/etc/nixos/configuration.nix # modify boot.loader.grub.device
nixos-install
```
