#!/bin/bash

. do-config.sh
#set -x

start_vm

ssh -t ${TEST_HOST_IP} sh -c \
	"
	sudo modprobe -r binfmt_mach-o;
	sudo rmmod binfmt_mach-o;
	sudo insmod /lib/modules/${KERNEL_VERSION}-${VERSION}/extra/${MODULE}
	sudo modprobe binfmt_mach-o;
	cd ${TEST_DIR};
	echo cd ${TEST_DIR};
	sudo sh -c \"echo 4096 > /proc/sys/vm/mmap_min_addr\";
	sudo \"cat /proc/sys/vm/mmap_min_addr\";
	./hello-static-Darwin-${ARCH} > /tmp/log-test.${ARCH}.txt;
	./hello-dynamic-Darwin-${ARCH} > /tmp/log-test.${ARCH}.txt;
	./hello-dynamic-sysenter-64-Darwin-${ARCH} > /tmp/log-test.${ARCH}.txt;
	dmesg >> /tmp/log-test.${ARCH}.txt
	"


scp ${TEST_HOST_IP}:/tmp/log-test.${ARCH}.txt .

exit_ok $0
