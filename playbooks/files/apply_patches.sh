#!/bin/bash -x

PATCHES_DIR=${1:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

cd ${PATCHES_DIR} || exit 1

# Apply patches
for PATCH in *.patch; do
    patch -p1 -N -d / < ${PATCH} ||
        { echo "[ERROR] ${PATCH} failed to apply";
         RET=1; }
done

exit ${RET}

