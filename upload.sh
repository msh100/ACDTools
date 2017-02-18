#!/bin/bash

# Config
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
source ${SCRIPTDIR}/vars

# Exit if already being executed
RUNNINGPID=`cat ${SCRIPTDIR}/upload.pid 2>/dev/null`
if [ -e /proc/${RUNNINGPID} ] && [ ! -z ${RUNNINGPID} ]; then
    echo Upload script already running
    exit 0
else
    echo $$ > ${SCRIPTDIR}/upload.pid
fi

# Sync Deletes
source ${SCRIPTDIR}/syncdeletes.sh

# Logic for force syncing on repeated failure
ULATTEMPTS=0

# Upload to Amazon Drive
until ${ACDCLI} upload -o --max-connections 5 ${MOUNTBASE}/local-encrypted/* ${ACDSUBDIR}
do
    ULATTEMPTS=$((ULATTEMPTS+1))
    echo "Some uploads didn't complete - initilising upload again after a sync (attempt ${ULATTEMPTS})"
    if [ "${ULATTEMPTS}" -ge 3 ]; then
        echo "Uploads failed 3 (or more) times in a row - doing a force sync"
        ${ACDCLI} sync -f
        ${ACDCLI} psync /
    else
        ${ACDCLI} sync
    fi
    sleep 60
done

echo "Upload Complete - Syncing changes"
${ACDCLI} sync

# Delete local files older than ${LOCALDAYS}
echo "Deleting local files older than ${LOCALDAYS} days"
find ${MOUNTBASE}/local-decrypted/ -type f -mtime +${LOCALDAYS} -exec rm -rf {} \;

# Cleanup pidfile
rm -rf ${SCRIPTDIR}/upload.pid
