# nixos

To install, set up your partitions:

```bash
sudo -i
lsblk
cfdisk <disk>
mkfs.ext4 -L nixos <partition>
mount <partition> /mnt
```

Then download configuration:

```bash
nixos-generate-config --root /mnt
mv /mnt/etc/nixos/hardware-configuration.nix .
rm -r /mnt/etc/nixos
git clone https://git.sr.ht/~knarkzel/nixos /mnt/etc/nixos
mv hardware-configuration.nix /mnt/etc/nixos
nano /mnt/etc/nixos/configuration.nix # edit boot.loader.grub.device
```

Finally, install:

```bash
nixos-install
```
