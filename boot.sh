#!/bin/bash

# Config
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
source ${SCRIPTDIR}/vars

# Unmount everything
echo "Unmounting all mountpoints"
# Todo: Not try to unmount the dirs which are not mounted
fusermount -u ${DATADIR}
fusermount -u ${MOUNTBASE}/acd-encrypted/
fusermount -u ${MOUNTBASE}/acd-decrypted/
fusermount -u ${MOUNTBASE}/local-encrypted/

# Make sure all dirs exist
mkdir -p ${MOUNTBASE}/acd-encrypted/ \
         ${MOUNTBASE}/acd-decrypted/ \
         ${MOUNTBASE}/local-encrypted/ \
		 ${MOUNTBASE}/local-decrypted/

# Sync ACD Nodes
${ACDCLI} psync ${ACDSUBDIR}
		 
# Mount all the things!
${ACDCLI} mount --modules="subdir,subdir=${ACDSUBDIR}" ${MOUNTBASE}/acd-encrypted/
encfs --extpass="echo ${ENCFSPASS}" --reverse \
    ${MOUNTBASE}/local-decrypted/ ${MOUNTBASE}/local-encrypted/
encfs --extpass="echo ${ENCFSPASS}" \
    ${MOUNTBASE}/acd-encrypted/ ${MOUNTBASE}/acd-decrypted/
unionfs-fuse -o cow,allow_other \
    ${MOUNTBASE}/local-decrypted=RW:${MOUNTBASE}/acd-decrypted=RO \
    ${DATADIR}
