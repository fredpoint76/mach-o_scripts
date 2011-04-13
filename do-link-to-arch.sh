#!/bin/bash

find . -type l -name \*.sh -exec rm {} \;

SCRIPTS="do-prep-vm.sh do-kernel-compile.sh do-kernel-install.sh do-module-compile.sh do-module-install.sh do-test.sh"
ARCHS="i386 x86_64 amd64 arm powerpc"

for script in $SCRIPTS
do
	for arch in $ARCHS
	do
		ln -s $script ${script%%.sh}-${arch}.sh
	done
done 
