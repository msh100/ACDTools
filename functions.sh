#!/bin/bash

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
