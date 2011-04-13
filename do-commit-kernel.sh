#!/bin/sh

. do-config.sh

do-clean.sh

cd ${KERNELSRC_DIR}
svn commit .
cd -
