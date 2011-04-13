#!/bin/bash

. do-config.sh

start_vm

ssh-copy-id ${TEST_HOST_IP}

echo "Configuring sudo..."
prep_vm_sudo

echo "Copying test binaries..."
prep_vm_bin

echo "Configuring grub..."
prep_vm_grub

exit_ok
