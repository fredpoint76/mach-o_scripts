#!/bin/bash

. do-config.sh
#set -x

start_vm

MODULE_INSTALL_PATH=/lib/modules/${KERNEL_VERSION}-${VERSION}/extra
echo "Creating directory..."
ssh -t ${TEST_HOST_IP} sudo mkdir -p ${MODULE_INSTALL_PATH}

echo "Uploading module to test host..."
scp ${KERNELSRC_DIR}/${MODULE_PATH}/${MODULE} \
	${TEST_HOST_IP}:/tmp/

echo "Installing the module..."
ssh -t ${TEST_HOST_IP} sudo mv /tmp/${MODULE} ${MODULE_INSTALL_PATH}

exit_ok $0
