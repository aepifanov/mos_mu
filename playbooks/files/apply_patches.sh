#!/bin/bash

PATCHES_DIR=${1:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}
IGNORE_APPLIED_PATCHES=${2:-$IGNORE_APPLIED_PATCHES}
IGNORE_APPLIED_PATCHES=${IGNORE_APPLIED_PATCHES:-"False"}

cd "${PATCHES_DIR}" &>/dev/null || exit 0

# Apply patches
RET=0
PATCHES=$(find . -type f -name "*.patch" | sort)
for PATCH in ${PATCHES}; do
    echo -e "\n-------- ${PATCH}"
    PATCH_OUT=$(patch -p1 -N -r- -d / < "${PATCH}")
    RES=$?
    echo -e "${PATCH_OUT}"
    if (( "${RES}" == 0 )); then
        if [ ${IGNORE_APPLIED_PATCHES,,} != "true" ]; then
            echo "[ERROR]  Failed to apply ${PATCH}"
            let "RET|=1"
            continue
        fi
        PATCH_RES=$(grep -Ev "patching|Skipping|ignored" <<< "${PATCH_RES}")
        if [ -n "${PATCH_RES}" ]; then
            echo "[ERROR]  Failed to apply ${PATCH}"
            let "RET|=1"
            continue
        fi
    fi
    echo "[OK]     Applied successfully"
done

exit ${RET}

