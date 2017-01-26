#!/bin/bash

# Config
SCRIPTDIR=`dirname "$(readlink -f "$0")"`
source ${SCRIPTDIR}/vars

# Sync Deletes
source ${SCRIPTDIR}/syncdeletes.sh

# Upload to Amazon Drive
until ${ACDCLI} upload -o --max-connections 5 ${MOUNTBASE}/local-encrypted/* ${ACDSUBDIR}
do
    echo "Some uploaded didn't complete - initilising upload again after a sync."
    ${ACDCLI} psync ${ACDSUBDIR}
    sleep 60
done

echo "Upload Complete - Syncing changes"
${ACDCLI} psync ${ACDSUBDIR}

# Delete local files older than ${LOCALDAYS}
echo "Deleting local files older than ${LOCALDAYS} days"
find ${MOUNTBASE}/local-decrypted/ -type f -mtime +${LOCALDAYS} -exec rm -rf {} \;

# Todo: Lock upload so it can't be done more than one at a time
