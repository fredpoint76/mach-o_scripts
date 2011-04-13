#!/bin/bash
export PATH=/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/home/fred/Documents/mach-o/scripts

. do-config.sh


cd ${KERNELSRC_DIR}
cp ${KERNEL_CONFIG} .config
exit_on_fail "Error. Can not find config. Exiting..."

# First clean
echo \
make-kpkg ${CROSS_OPTIONS} clean

# Now compiling a brand new kernel
#echo \
make-kpkg ${CROSS_OPTIONS} --rootcmd fakeroot --initrd \
		--append-to-version=-${VERSION} kernel-image kernel-headers


exit_on_fail "Error in compiling. Exiting..."

cd -

# Save the debian packages
mv ${HEADER_DEB} ${IMAGE_DEB} ${KERNEL_ARCHIVES_DIR}
# Save the Module.symvers (Helpfull for module compilation)
cp ${KERNELSRC_DIR}/Module.symvers ${KERNEL_SYMVER}

exit_ok $0

