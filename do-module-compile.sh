#!/bin/bash
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/home/fred/Documents/mach-o/scripts

. do-config.sh


cd ${KERNELSRC_DIR}
cp ${KERNEL_CONFIG} .config
exit_on_fail "Error. Can not find config. Exiting..."

# First clean all
make mrproper
cp ${KERNEL_CONFIG} .config
cp ${KERNEL_SYMVER} Module.symvers

make prepare

# First clean
make M=fs/mach-o clean

# Now compiling the module
case "$ARCH" in
	"powerpc")
		# See bug https://bugzilla.kernel.org/show_bug.cgi?id=11143
		make M=arch/powerpc/lib
		;;
esac

make M=scripts/mod
make M=fs/mach-o


exit_on_fail "Error in compiling. Exiting..."

cd -

exit_ok $0
