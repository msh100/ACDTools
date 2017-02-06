#!/bin/bash

# Config
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
source ${SCRIPTDIR}/vars

ACDMOUNT="${MOUNTBASE}/acd-encrypted/"
SEARCHDIR="${MOUNTBASE}/local-decrypted/.unionfs-fuse/"
MATCHED=$(find ${SEARCHDIR} -type f -name '*_HIDDEN~')

# Set the for delimiter
IFS='
'

# For every file listed by the find command
for file in ${MATCHED}; do

    # Trim off the full path and hidden flag to get the real file path
    FILENAME=$(echo ${file} | grep -oP "^${SEARCHDIR}\K.*")
    FILENAME=${FILENAME%_HIDDEN~}

    ENCNAME=$(encfsctl encode --extpass="echo ${ENCFSPASS}" ${ACDMOUNT} "${FILENAME}")

    ACDEXIST=$(${ACDCLI} ls ${ACDSUBDIR}/${ENCNAME} > /dev/null 2>&1; echo $?)
    if [ "${ACDEXIST}" -eq "0" ]; then
        # File does exist, delete it from Amazon Drive
        echo "${file} exists on Amazon Drive - deleting"
        until `${ACDCLI} rm ${ACDSUBDIR}/${ENCNAME}`
        do
            # Failed delete - sleep and retry
            echo "Delete failed, trying again in 30 seconds"
            sleep 30
        done

        echo "${FILENAME} deleted from Amazon Drive"
    else
        echo "${file} is not on Amazon Drive"
    fi

    # Remove the UnionFS hidden object
    rm -rf ${file}

done

# Sync Amazon Drive changes
${ACDCLI} psync -r ${ACDSUBDIR}
