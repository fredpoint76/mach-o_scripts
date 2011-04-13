#!/bin/bash

. do-config.sh

case "$ARCH" in
	"arm")
		echo "Extract the kernel bzImage"
		extract_kernel_from_deb \
			"${KERNEL_ARCHIVES_DIR}/${IMAGE_DEB}" \
			"./boot/${KERNEL_VMLINUZ}" \
			"${KERNEL_ARCHIVES_DIR}/${KERNEL_VMLINUZ}.${ARCH}"
		;;
	"i386")
		;;
	"amd64")
		;;
	*)
		;;
esac
#set -x

start_vm

echo "See if we need to reboot to the base kernel..."
current_kernel=`ssh -t ${TEST_HOST_IP} sudo "uname -r"`


if [ "${KERNEL_VERSION}-${VERSION}" == "${current_kernel%%?}" ]; then
	echo "Reboot to base kernel..."
	ssh -t ${TEST_HOST_IP} sudo "grub-reboot \"${QEMU_DEFAULT_KERNEL_ENTRY}\""
	stop_vm
	start_vm
fi

echo "Do some cleanup..."
echo "Remove all previously upload deb files..."
ssh -t ${TEST_HOST_IP} sudo "rm -f ${KERNEL_ARCHIVES_DIR}/*.deb"

echo "Remove previously installed mach-o kernel..."
#ssh ${TEST_HOST_IP} sudo "sh -c \"yes n | apt-get remove --purge --force-yes --yes ${IMAGE} ${HEADER}\""
ssh -t ${TEST_HOST_IP} sudo "sh -c \"yes n | apt-get remove --purge --force-yes --yes '.*macho.*'\""
ssh -t ${TEST_HOST_IP} sudo "rm -Rf /lib/modules/*macho*"

echo "Upload the new kernel..."
ssh -t ${TEST_HOST_IP} mkdir -p ${KERNEL_ARCHIVES_DIR}
scp ${KERNEL_ARCHIVES_DIR}/${HEADER_DEB} \
	${KERNEL_ARCHIVES_DIR}/${IMAGE_DEB}  \
	${TEST_HOST_IP}:${KERNEL_ARCHIVES_DIR}

echo "Install the new kernel..."
ssh -t ${TEST_HOST_IP} sudo "sh -c \"yes n | dpkg -i ${KERNEL_ARCHIVES_DIR}/${HEADER_DEB}\""
ssh -t ${TEST_HOST_IP} sudo "sh -c \"yes n | dpkg -i ${KERNEL_ARCHIVES_DIR}/${IMAGE_DEB}\""

echo "Remove the deb files..."
ssh -t ${TEST_HOST_IP} sudo "rm -f ${KERNEL_ARCHIVES_DIR}/${HEADER_DEB} ${KERNEL_ARCHIVES_DIR}/${IMAGE_DEB}"


# Before halting the VM
case "$ARCH" in
	"i386"|"amd64")
		# FIXME
		ssh -t ${TEST_HOST_IP} "sudo update-initramfs -c -k ${KERNEL_VERSION}-${VERSION} "
		ssh -t ${TEST_HOST_IP} "sudo grub-set-default \"Ubuntu, with Linux ${KERNEL_VERSION}-${VERSION}\""
		ssh -t ${TEST_HOST_IP} "sudo update-grub"
		;;
	"arm")
		ssh -t ${TEST_HOST_IP} "sudo update-initramfs -c -k ${KERNEL_VERSION}-${VERSION} "
		ssh -t ${TEST_HOST_IP} "ls -l /boot"
		scp ${TEST_HOST_IP}:/boot/${KERNEL_VMLINUZ} ${KERNEL_ARCHIVES_DIR}/${KERNEL_VMLINUZ}.${ARCH}
		scp ${TEST_HOST_IP}:/boot/${KERNEL_INITRD} ${KERNEL_ARCHIVES_DIR}/${KERNEL_INITRD}.${ARCH}
		;;
	*)
		;;
esac

stop_vm

exit_ok $0
