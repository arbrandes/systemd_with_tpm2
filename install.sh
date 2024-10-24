#!/bin/bash


function install_crypt_setup_mod_scripts()
{
    mkdir -p patched
    pushd patched >& /dev/null

    cp /usr/lib/cryptsetup/functions cryptsetup_functions
    cp /usr/share/initramfs-tools/scripts/local-top/cryptroot cryptroot

    patch cryptsetup_functions ../patches/cryptsetup_functions.patch
    patch cryptroot ../patches/cryptroot.patch

    cp cryptsetup_functions /usr/lib/cryptsetup/functions
    cp cryptroot /usr/share/initramfs-tools/scripts/local-top/cryptroot

    popd >& /dev/null

    # Install the initramfs hook to include the required program and libtss2 in
    # the initramfs
    cp scripts/systemd_cryptsetup_hook /etc/initramfs-tools/hooks
}

function update_initramfs()
{
    update-initramfs -u
}

function tldr_just_work()
{
    install_crypt_setup_mod_scripts && \
    update_initramfs && \
    echo SystemD with TPM2 installation complete.
}


if [[ "${EUID}" -ne 0 ]] ; then
	echo "This script must be run as root."
	exit 1
fi

tldr_just_work
