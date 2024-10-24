
# Systemd-CryptSetup operation combined with initramfs-tools

### TLDR:

Check if Ubuntu recognize your TPM chip

    systemd-cryptenroll --tpm2-device=list

Check current LUKS info

    sudo cryptsetup luksDump /dev/nvme0n1p3

Enroll TPM as unlocker

    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p3

Check current LUKS info after TPM enrollment

    sudo cryptsetup luksDump /dev/nvme0n1p3

Edit /etc/crypttab to something like

    nvme0n1p3_crypt UUID=ff098ab6-2a46-11ee-be56-0242ac120002 none luks,discard,tpm2-device=auto

Run

    sudo ./install.sh

### Slightly longer:

If you have a LUKS container and want it to unlock, without reading the scripts, run `sudo ./install.sh`.  This will:
    1. patch cryptsetup scripts, include necessary components in the initramfs
    2. update the initramfs
and then you may need to use 'systemd-cryptenroll' to enroll a LUKS TPM2 key, if you haven't done that already.

Current installations of Ubuntu come with SystemD that are built to support TPM2 already.

### I want to understand!
0. Read the scripts for full details of what's happening.  They've been documented by function names, and should be reasonably easy to understand both what's happening and why it is happening.
	start with install.sh 'tldr_just_Work' and read the rest of the functions from there.
1. patches/cryptroot.patch
	patches /usr/share/initramfs/local-top/cryptroot
2. patches/cryptsetup_functions.patch
	replaces /usr/lib/cryptsetup/functions.sh
3. systemd_cryptsetup_hook
	adds to /etc/initramfs-tools/hooks

## Operation:
These files build on the 'cryptroot' module in initramfs-tools/cryptsetup to allow the ```bash /etc/crypttab``` file to support the 'tpm-device=xxx' option and pass it through to the systemd-crypsetup application to allow automatically decrypting a device using LUKS and a TPM.

# Licensing #
I've been unable to establish who publishes the files I've patched and how they are licensed, so I've only included the patch here so I do not infringe anyone's copyright or break licensing.

# Full Process #
This is a rough and ready summary of the process to get a system running with an encrypted root.  It isn't as detailed as I'd like and there are more ways to get this to work (Work in Progress!).
A lot of this has been developed from the excellent articles in Arch Linux, so if there are steps missing you may need to read around the issues, or ask in the 'Issues' and someone (possibly me) will answer when they can.

Potentially useful pages for more context:
- https://wiki.archlinux.org/title/Trusted_Platform_Module#Data-at-rest_encryption_with_LUKS
- https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
- https://wiki.archlinux.org/title/Data-at-rest_encryption

NB: big thanks to the authors of these articles - they helped me get most of the way here!


(using an Ubuntu Desktop live environment some of 1, 2 & 3 probably needs to be done before starting the installer)

1. create partitions 
   - assign space for unencrypted EFI system partition (stores grub2, Linux Kernel and initrd image or other system software)
   - assign space for the LVM PV and any other un-encrypted partitions you may want
   - assign space for the un-encrypted /boot partition (which may be removed if using a unified kernel image after the system has been configured) - done at the end to allow extending the PV partition in to it with pvresize.
2. Format with LUKS
3. Use lvm
   - pvcreate
   - vgcreate
   - lvcreate
4. Install Ubuntu in to correct LV and unencrypted EFI system and /boot partitions!
5. Reboot in to the new Ubuntu environment:
    - the system halts in the initrd shell as it does not know how to unlock the LUKS (crypttab not yet created) and find the LV used as root.
    - the user has to manually unlock the LUKS partition with cryptsetup, then exit the shell and the system continues to boot.
6. Install git, get this repo, run `sudo ./install.sh`
7. Store a key in the TPM for LUKS
   `systemd-cryptenroll`
8. Reboot.

NB:  This doesn't protect against a modified initrd as yet.  That's another stage of configuring secure boot and creating an (optionally signed) Unified Kernel Image (or enabling key verification with GRUB2 or something along those lines!)  But this is a good step on the way!
NB2:  Apparently the Linux kernel now measures it's own initrd, so if the systemd-cryptenroll is called with the correct registers, then that may be covered off (see issue 2) linked below.

# Further Security #

## Security Discussion (Issue) ##
Check [this issue](https://github.com/wmcelderry/systemd_with_tpm2/issues/2) for more details about below and any discussion of other attacks to be aware of - or to share details of other attacks that users should be aware of!

## Init RD attack ##
You may want to create a unified kernel - this protects against a modified initrd attack. See: [this repo](https://github.com/wmcelderry/unified_kernel_image)]

## SecureBoot ##
SecureBoot uses cryptographically signed bootloaders to ensure that the BIOS will not even load an attacker's OS on your hardware.  Useful if you are concerned about an attacker repurposing your kit.  There's nothing here for now, so read around the topic and feel free to create an issue with comments or even a Pull Request with a link to your repository here.
