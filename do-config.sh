#!/bin/bash


# General parameters
#KERNEL_VERSION=2.6.30.4
#KERNEL_VERSION=2.6.32.11
#KERNEL_VERSION=2.6.35.4
KERNEL_VERSION=2.6.35.7
VERSION=macho-r1
export CONCURRENCY_LEVEL=3
BASE_DIR=${HOME}/Documents/mach-o
QEMU_HD_BASE=${BASE_DIR}/qemu/harddisks.clean

if [ -z "$ARCH" ]; then
	ARCH=`echo $0 | sed 's/^.*-\([a-z0-9_]*\).sh$/\1/'`
fi

TEST_USER=fred
# Directories
BASE_DIR=${HOME}/Documents/mach-o
KERNELSRC_DIR=${BASE_DIR}/linux-${KERNEL_VERSION}
# Parameters for automatic installation
KERNEL_ARCHIVES_DIR=${BASE_DIR}/kernel_archives
# Parameters for automatic tests
TEST_DIR=${BASE_DIR}/mach-o_testing/bin-arch

KERNEL_CONFIG=${BASE_DIR}/kernel_config/config.${ARCH}.${KERNEL_VERSION}
KERNEL_SYMVER=${BASE_DIR}/kernel_config/Module.symvers.${ARCH}.${KERNEL_VERSION}

KERNEL_VMLINUZ=vmlinuz-${KERNEL_VERSION}-${VERSION}
KERNEL_INITRD=initrd.img-${KERNEL_VERSION}-${VERSION}




case "$ARCH" in
	"i386")
		# CROSS COMPILING FOR i386 TARGET on AMD64
		TEST_HOST_NB=10
		TEST_HOST_MAC=52:54:00:12:34:${TEST_HOST_NB}
		TEST_HOST_IP=192.168.0.${TEST_HOST_NB}
		QEMU=/usr/bin/qemu-system-i386
		QEMU_HD=${QEMU_HD_BASE}/ubuntu-i386.qcow2
		VM_NAME=Ubuntu
		export ARCH
		export SUBARCH=${ARCH}
		CROSS_COMPILE=-
		export OBJCOPY=objcopy
		CROSS_OPTIONS="--arch=${SUBARCH} --subarch=${ARCH} \
					--cross_compile=${CROSS_COMPILE}"
		export DEB_HOST_ARCH=${ARCH}
		;;
	"amd64")
		TEST_HOST_NB=11
		TEST_HOST_MAC=52:54:00:12:34:${TEST_HOST_NB}
		TEST_HOST_IP=192.168.0.${TEST_HOST_NB}
		QEMU=/usr/bin/qemu-system-x86_64
		QEMU_HD=${QEMU_HD_BASE}/ubuntu-amd64.qcow2
		QEMU_DEFAULT_KERNEL_ENTRY="Ubuntu, with Linux 2.6.35-22-server"
		VM_NAME=Ubuntu-64
		SUBARCH="${ARCH}"
		export OBJCOPY=objcopy
		;;
	"x86_64")
		TEST_HOST_NB=11
		TEST_HOST_MAC=52:54:00:12:34:${TEST_HOST_NB}
		TEST_HOST_IP=192.168.0.${TEST_HOST_NB}
		QEMU=/usr/bin/qemu-system-x86_64
		QEMU_HD=${QEMU_HD_BASE}/ubuntu-amd64.qcow2
		VM_NAME=Ubuntu-64
		SUBARCH="${ARCH}"
		export OBJCOPY=objcopy
		;;
	"arm")
		# CROSS COMPILING FOR ARM TARGET
		TEST_HOST_NB=12
		TEST_HOST_MAC=52:54:00:12:34:${TEST_HOST_NB}
		TEST_HOST_IP=192.168.0.${TEST_HOST_NB}
		QEMU=/usr/bin/qemu-system-arm
		QEMU_HD=${QEMU_HD_BASE}/ubuntu-arm.qcow2
		QEMU_BASE_KERNEL=${KERNEL_ARCHIVES_DIR}/vmlinuz-2.6.32-21-versatile.${ARCH}
		QEMU_BASE_INITRD=${KERNEL_ARCHIVES_DIR}/initrd.img-2.6.32-21-versatile.${ARCH}
		QEMU_TEST_KERNEL=${KERNEL_ARCHIVES_DIR}/${KERNEL_VMLINUZ}.${ARCH}
		QEMU_TEST_INITRD=${KERNEL_ARCHIVES_DIR}/${KERNEL_INITRD}.${ARCH}
		QEMU_OPTIONS='-m 256 -M versatilepb -cpu cortex-a8'
		QEMU_KERNEL_OPTIONS='root=/dev/sda mem=256M devtmpfs.mount=0 rw'
		export ARCH
		export SUBARCH=armel
		export CROSS_COMPILE=arm-linux-gnueabi-
		export OBJCOPY=arm-linux-gnueabi-objcopy
		CROSS_OPTIONS="--arch=${SUBARCH} --cross_compile=${CROSS_COMPILE}"
		export DEB_HOST_ARCH=armel
		;;
	"powerpc")
		TEST_HOST_NB=13
		TEST_HOST_MAC=52:54:00:12:34:${TEST_HOST_NB}
		TEST_HOST_IP=192.168.0.${TEST_HOST_NB}
		QEMU=/usr/local/bin/qemu-system-ppc
		QEMU_HD=${QEMU_HD_BASE}/ubuntu-ppc.qcow2
		QEMU_OPTIONS='-m 512'
		export ARCH
		export SUBARCH="${ARCH}"
		export CROSS_COMPILE=powerpc-linux-gnu-
		export OBJCOPY=powerpc-linux-gnu-objcopy
		CROSS_OPTIONS="--arch=${SUBARCH} --cross_compile=${CROSS_COMPILE}"
		;;
	*)
		ARCH="i386"
		SUBARCH="${ARCH}"
		CROSS_COMPILE=-
		CROSS_OPTIONS="--arch=${SUBARCH} --subarch=${ARCH} \
					--cross_compile=${CROSS_COMPILE}"
		export DEB_HOST_ARCH=i386
		TEST_HOST_IP=192.168.0.9
		;;
esac


REVISION=10.00.Custom
HEADER=linux-headers-${KERNEL_VERSION}-${VERSION}
IMAGE=linux-image-${KERNEL_VERSION}-${VERSION}
HEADER_DEB=${HEADER}_${KERNEL_VERSION}-${VERSION}-${REVISION}_${SUBARCH}.deb
IMAGE_DEB=${IMAGE}_${KERNEL_VERSION}-${VERSION}-${REVISION}_${SUBARCH}.deb
MODULE=binfmt_mach-o.ko
MODULE_PATH=fs/mach-o

#Parameters for qemu




# Some usefull functions

exit_ok() {
	echo "$*"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!! OK !!!!!!!!!!!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	if [ "$0" == "bash" ]; then
		return 0
	else
		exit 0
	fi
}

exit_nok() {
	echo "$*"
	echo "-------------- FAIL --------------"
	if [ "$0" == "bash" ]; then
		return 1
	else
		exit 1
	fi
}

exit_on_success() {
	(($?)) || { echo; exit_nok "$*"; }
}
exit_on_fail() {
	(($?)) && { echo; exit_nok "$*"; }
}

alias do_ssh='ssh -t -o StrictHostKeyChecking=no'

link_to_kernel() {
	rm -f kernel
	ln -s linux-${KERNEL_VERSION} ${KERNEL_SRC}
}

extract_kernel_from_deb() {
	 dpkg --fsys-tarfile "$1" | tar xOf - "$2" > "$3"
}

start_vm() {
	case "$ARCH" in
		"arm")
			start_vm_qemu
			;;
		"powerpc")
			start_vm_qemu
			;;
		"powerpc64")
			start_vm_qemu
			;;
		"i386")
			#start_vm_vbox
			start_vm_qemu
			;;
		"amd64"|"x86_64")
			start_vm_qemu
			;;
		*)
			;;
	esac
}


create_bridge() {
	brctl show br0 | grep -q br0
	if [ $? -ne 0 ];then
		sudo /usr/sbin/brctl addbr br0
		sudo /sbin/ifconfig eth0 0.0.0.0 promisc up
		sudo /usr/sbin/brctl addif br0 eth0
		sudo /sbin/dhclient br0
		sudo /sbin/iptables -F FORWARD
	fi
}

destroy_bridge() {
	sudo /usr/sbin/brctl delif br0 eth0
	sudo ifconfig br0 down
	sudo /usr/sbin/brctl delbr br0
	sudo /sbin/dhclient eth0
}

start_qemu() {
	echo $0 | grep -q 'install'
	if [ $? -eq 0 ];then
		# Installation mode: So we will use BASE kernel and initrd 
		QEMU_KERNEL=${QEMU_BASE_KERNEL}
		QEMU_INITRD=${QEMU_BASE_INITRD}
	else
		# Test mode: Use the kernel specified in do-config
		QEMU_KERNEL=${QEMU_TEST_KERNEL}
		QEMU_INITRD=${QEMU_TEST_INITRD}
	fi
	case "$ARCH" in
		"arm")
			kernel_option="-kernel ${QEMU_KERNEL}"
			initrd_option="-initrd ${QEMU_INITRD}"
			;;
		"ppc"|"ppc64")
			;;
		"i386"|"amd64")
			;;
		*)
			;;
	esac
	if [ -n "${QEMU_KERNEL_OPTIONS}" ]; then
		append_option="-append ${QEMU_KERNEL_OPTIONS}"
	fi
	echo \
	sudo ${QEMU} \
		${kernel_option} \
		${initrd_option} \
			-hda ${QEMU_HD} \
			-net nic,macaddr=${TEST_HOST_MAC},vlan=0 -net tap,vlan=0,ifname=tap${TEST_HOST_NB},script=/etc/qemu-ifup \
			${QEMU_OPTIONS} \
			${append_option} &
			# -nographic

	sudo ${QEMU} \
		${kernel_option} \
		${initrd_option} \
			-hda ${QEMU_HD} \
			-net nic,macaddr=${TEST_HOST_MAC},vlan=0 -net tap,vlan=0,ifname=tap${TEST_HOST_NB},script=/etc/qemu-ifup \
			${QEMU_OPTIONS} \
			${append_option} &

}

start_vm_qemu() {
	# Start VM if it have not been started yet
	ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo"

	if [ $? -ne 0 ]; then
		# Setup for Qemu
		mount_disk
		create_bridge

		start_qemu
		sleep 1

		pidof ${QEMU}
		exit_on_fail "Can not launch VM. Exiting..."


		retry=120
		ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo" > /dev/null 2>&1
		while [ $? -ne 0 -a $retry -ne 0 ] ; do  
			retry=$((retry-1))
			echo -n "."
			ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo" > /dev/null 2>&1
		done
		echo
		if [ $? -ne 0 ]; then
			echo
			echo "Can not reach VM. Exiting..."
			exit_nok
		fi
	fi

}

stop_vm() {
	ssh -t ${TEST_HOST_IP} sudo halt
	case "$ARCH" in
		"arm")
			stop_vm_qemu
			;;
		"ppc")
			stop_vm_qemu
			;;
		"ppc64")
			stop_vm_qemu
			;;
		"i386")
			#stop_vm_vbox
			stop_vm_qemu
			;;
		"amd64")
			stop_vm_qemu
			;;
		*)
			;;
	esac
}


stop_vm_qemu() {
	retry=60
	sleep 20
	#destroy_bridge

	if [ -n "`pidof ${QEMU}`" ]; then
		sudo kill `pidof ${QEMU}`
		pidof ${QEMU}
		while [ $? -eq 0 -a $retry -ne 0 ] ; do  
			retry=$((retry-1))
			sleep 1
			echo -n "."
			pidof ${QEMU}
		done
		exit_on_success "Can't stop the VM. Exiting..."
	fi
}

prep_vm_sudo() {
	
	ssh -t ${TEST_HOST_IP} "sudo sh -c '
grep toto /etc/sudoers;
echo $?;
hostname
if [ $? -ne 0 ]; then
cat >> /etc/sudoers << EOF 

%admin ALL=(ALL) ALL
%sudo ALL=NOPASSWD: ALL
EOF
fi
'"
	ssh -t ${TEST_HOST_IP} "sudo usermod -a -G admin,sudo $TEST_USER"
}

prep_vm_bin() {
	# !!! FIXME !!!: Copy binaries to the test host
	ssh -t ${TEST_HOST_IP} "mkdir -p ${TEST_DIR}"
	scp ${TEST_DIR}/* ${TEST_HOST_IP}:${TEST_DIR}/
}

prep_vm_grub() {
	ssh -t ${TEST_HOST_IP} "sudo sed -i '/GRUB_DEFAULT=saved/!s/^GRUB_DEFAULT=.*$/GRUB_DEFAULT=saved\nGRUB_SAVEDEFAULT=true/' /etc/default/grub"
}

# Obsolete functions
stop_vm_vbox() {
	retry=60
	VBoxManage list runningvms | grep -q "\"${VM_NAME}\""
	while [ $? -eq 0 -a $retry -ne 0 ] ; do  
		retry=$((retry-1))
		sleep 1
		echo -n "."
		VBoxManage list runningvms | grep -q "\"${VM_NAME}\""
	done
	exit_on_success "Can't stop the VM. Exiting..."
}

start_vm_vbox() {
	# Start VM if it have not been started yet
	ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo"

	if [ $? -ne 0 ]; then
		# Setup for VirtualBox
		disable_kvm

		VBoxHeadless -s ${VM_NAME} &
		sleep 1

		pidof VBoxHeadless
		exit_on_fail "Can not launch VM. Exiting..."


		retry=120
		ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo"
		while [ $? -ne 0 -a $retry -ne 0 ] ; do  
			retry=$((retry-1))
			echo -n "."
			ssh -o ConnectTimeout=1 ${TEST_HOST_IP} "echo"
		done
		exit_on_fail "Can not reach VM. Exiting..."

		echo
	fi
}

mount_disk() {
	# harpo
	gvfs-mount -d /dev/sdb2 2> /dev/null
}

disable_kvm() {
	sudo modprobe -r kvm_intel
	sudo modprobe -r kvm
}

enable_kvm() {
	sudo modprobe kvm_intel
}


kernel_version() {
	a=$1;b=$2;c=$3;
	echo $(( (((a) << 16) + ((b) << 8) + (c)) ))
}
kernel_version_dotted() {
	echo $1 | IFS="." read a b c
	kernel_version $a $b $c
}
#QEMU_OPTIONS="${QEMU_OPTIONS} -cpu cortex-a8"
#~ if [[ `kernel_version_dotted 2.6.35` -eq `kernel_version_dotted ${KERNEL_VERSION}` ]]; then
	#~ QEMU_OPTIONS="${QEMU_OPTIONS} -cpu cortex-a9" 
#~ else
	#~ QEMU_OPTIONS="${QEMU_OPTIONS} -cpu cortex-a8" 
#~ fi 


