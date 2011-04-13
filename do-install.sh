#!/bin/sh

. do-config.sh

sudo apt-get remove --purge --force-yes --yes ${IMAGE} ${$HEADER} 
sudo dpkg -i ${HEADER_DEB}
sudo dpkg -i ${IMAGE_DEB} 
