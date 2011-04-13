#!/bin/bash

. do-config.sh

cd ${KERNELSRC_DIR}
make-kpkg clean
for i in arm i386 powerpc x86_64; do ARCH=$i make mrproper; done
rm drivers/gpu/drm/radeon/*_reg_safe.h
rm ubuntu/aufs/conf.str.tmp ubuntu/aufs/conf.str
rm security/apparmor/capability_names.h security/apparmor/af_names.h security/apparmor/rlim_names.h security/selinux/av_permissions.h

svn update debian
cd -
