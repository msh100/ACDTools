#!/bin/bash

# Config
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
source ${SCRIPTDIR}/vars

# Include functions for unmounting
source ${SCRIPTDIR}/functions.sh

# Unmount everything
echo "Unmounting all mountpoints"
ACDToolsUnmount ${DATADIR}
ACDToolsUnmount ${MOUNTBASE}/acd-encrypted/
ACDToolsUnmount ${MOUNTBASE}/acd-decrypted/
ACDToolsUnmount ${MOUNTBASE}/local-encrypted/

# Make sure all dirs exist
mkdir -p ${MOUNTBASE}/acd-encrypted/ \
         ${MOUNTBASE}/acd-decrypted/ \
         ${MOUNTBASE}/local-encrypted/ \
         ${MOUNTBASE}/local-decrypted/

# Sync ACD Nodes
${ACDCLI} psync ${ACDSUBDIR}

# Mount all the things!
screen -dm -S acd-mount ${ACDCLI} mount -fg \
    --modules="subdir,subdir=${ACDSUBDIR}" ${MOUNTBASE}/acd-encrypted/
encfs --extpass="echo ${ENCFSPASS}" --reverse \
    ${MOUNTBASE}/local-decrypted/ ${MOUNTBASE}/local-encrypted/
encfs --extpass="echo ${ENCFSPASS}" \
    ${MOUNTBASE}/acd-encrypted/ ${MOUNTBASE}/acd-decrypted/
unionfs-fuse -o cow,allow_other \
    ${MOUNTBASE}/local-decrypted=RW:${MOUNTBASE}/acd-decrypted=RO \
    ${DATADIR}
