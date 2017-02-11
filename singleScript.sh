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

# Print usage
function ACDToolsUsage {
    echo $"Usage: $0 {mount|unmount|upload|sync|syncdeletes}"
}


# Determins what the user wants to do

ACTION=${*: -1:1} # TODO: This takes the last arg, doubt it is reliable.

case "${ACTION}" in
    mount)
        echo 1
        ;;
    unmount)
        echo 2
        ;;
    upload)
        echo 3
        ;;
    sync)
        echo 4
        ;;
    syncdeletes)
        echo 5
        ;;
    usage)
        ACDToolsUsage
        ;;
    *)
        ACDToolsUsage
        exit 1
esac
