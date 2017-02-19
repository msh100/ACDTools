#!/bin/bash

# ACDTools

# Set directory of current script
# http://stackoverflow.com/a/246128/811814
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"


# Determine configuration file path and load it

# If -c is set, then set that value as ${OPTARG}
while getopts ":c:" opt; do
    case $opt in
        c)
            echo "User defined configuration file at ${OPTARG}"
            CONFOPT=${OPTARG}
            ;;
    esac
done

if [ ${CONFOPT} ] && [ -f ${CONFOPT} ]; then
    # Ensure user defined configuration exists
    CONFIGPATH=${CONFOPT}
elif [ -f ${PWD}/vars ]; then
    # Check if configuration exists in PWD
    CONFIGPATH=${PWD}/vars
elif [ -f ${DIR}/vars ]; then
    # Check if configuration exists in the script directory
    CONFIGPATH=${DIR}/vars
fi

# If no valid configuation path, kill the script.
if [ ! ${CONFIGPATH} ]; then
    echo -n 'No valid configuration can be found. '
    echo    'Use -c to define a configuration.'
    exit 1
else
    echo "Using configuration at ${CONFIGPATH}"
    source ${CONFIGPATH}
fi

# TODO: Config validity


# Functions

# Unmount a mountpoint. Will not unmount if not already mounted.
# TODO: fusermount does not exist on OS X, make compatible.
function ACDToolsUnmount {
    # Check if $1 is a mountpoint
    ISMOUNTPOINT=`mountpoint ${1} > /dev/null 2>&1`
    if [ $? -eq "0" ]; then
        echo "Unmounting ${1}"
        fusermount -u ${1}
    else
        echo "Can not unmount ${1} - it is not mounted"
    fi
}

# Function to unmount all mountpoints associated with ACDTools
function ACDToolsUnmountAll {
    echo "Unmounting all ACDTools mountpoints"
    ACDToolsUnmount ${DATADIR}
    ACDToolsUnmount ${MOUNTBASE}/acd-encrypted/
    ACDToolsUnmount ${MOUNTBASE}/acd-decrypted/
    ACDToolsUnmount ${MOUNTBASE}/local-encrypted/
}

# Function to sync node cache 
function ACDToolsSyncNodes {
    echo "Syncing acdcli node cache database"
    ${ACDCLI} psync / # Sync root node first because of acdcli bug
    #${ACDCLI} sync
}

# Function to mount everything for ACDTools
function ACDToolsMount {
    # Create mountpoint directories
    mkdir -p ${MOUNTBASE}/acd-encrypted/ \
        ${MOUNTBASE}/acd-decrypted/ \
        ${MOUNTBASE}/local-decrypted/ \
        ${MOUNTBASE}/local-encrypted/ \
        ${DATADIR} 2>/dev/null

    # Ensure the ACD Subdir exists
    ${ACDCLI} mkdir -p ${ACDSUBDIR}

    # Mount everything
    screen -dm -S acd-mount ${ACDCLI} mount -fg \
        --modules="subdir,subdir=${ACDSUBDIR}" ${MOUNTBASE}/acd-encrypted/
    encfs --extpass="echo ${ENCFSPASS}" --reverse \
        ${MOUNTBASE}/local-decrypted/ ${MOUNTBASE}/local-encrypted/
    encfs --extpass="echo ${ENCFSPASS}" \
        ${MOUNTBASE}/acd-encrypted/ ${MOUNTBASE}/acd-decrypted/
    unionfs-fuse -o cow,allow_other \
        ${MOUNTBASE}/local-decrypted=RW:${MOUNTBASE}/acd-decrypted=RO \
        ${DATADIR}
}

# Function to print usage of ACDTools
function ACDToolsUsage {
    echo $"Usage: $0 {mount|unmount|upload|sync|syncdeletes}"
}

# Reflect unionfs deleted file objects on Amazon Drive
function ACDToolsSyncDeletes {
    ACDMOUNT="${MOUNTBASE}/acd-encrypted/"
    SEARCHDIR="${MOUNTBASE}/local-decrypted/.unionfs-fuse/"

    if [ -d "$DIRECTORY" ]; then
       MATCHED=$(find ${SEARCHDIR} -type f -name '*_HIDDEN~')
    else
        # There's no need to proceed with this function
        echo "No .unionfs-fuse/ directory found, nothing to delete"
        return
    fi

    # Set the for delimiter
    IFS='
    '

    # For every file listed by the find command
    for file in ${MATCHED}; do

        # Trim off the full path and hidden flag to get the real file path
        FILENAME=$(echo ${file} | grep -oP "^${SEARCHDIR}\K.*")
        FILENAME=${FILENAME%_HIDDEN~}

        ENCNAME=$(encfsctl encode --extpass="echo ${ENCFSPASS}" \
            ${ACDMOUNT} "${FILENAME}")

        ACDEXIST=$(${ACDCLI} ls ${ACDSUBDIR}/${ENCNAME} > /dev/null 2>&1; \
            echo $?)
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
    ACDToolsSyncNodes
}


# Determins what the user wants to do

ACTION=${*: -1:1} # TODO: This takes the last arg, doubt it is reliable.

case "${ACTION}" in
    mount)
        ACDToolsUnmountAll
        ACDToolsSyncNodes
        ACDToolsMount
        ;;
    unmount)
        ACDToolsUnmountAll
        ;;
    upload)
        echo 3
        # ACDToolsSyncDeletes
        # then upload
        ;;
    sync)
        echo 4
        ;;
    syncdeletes)
        ACDToolsSyncDeletes
        ;;
    usage)
        ACDToolsUsage
        ;;
    *)
        ACDToolsUsage
        exit 1
esac
