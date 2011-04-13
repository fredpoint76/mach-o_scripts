#!/bin/bash

sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 ubuntu-amd64.qcow
sudo qemu-nbd --connect=/dev/nbd1 ubuntu-ppc.qcow2
sudo qemu-nbd --connect=/dev/nbd2 ubuntu-arm.qcow2

sudo mount /dev/nbd2 /home/fred/Documents/mach-o/qemu/harddisks.clean/arm
sudo mount /dev/nbd0p1 /home/fred/Documents/mach-o/qemu/harddisks.clean/amd64
sudo mount /dev/nbd1p3 /home/fred/Documents/mach-o/qemu/harddisks.clean/ppc

sudo umount /dev/nbd2 
sudo umount /dev/nbd0p1
sudo umount /dev/nbd1p3

sudo qemu-nbd --disconnect /dev/nbd0
sudo qemu-nbd --disconnect /dev/nbd1
sudo qemu-nbd --disconnect /dev/nbd2
