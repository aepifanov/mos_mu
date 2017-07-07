#!/bin/bash

PATCHES_DIR=${1:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}
IGNORE_APPLIED_PATCHES=${2:-$IGNORE_APPLIED_PATCHES}
IGNORE_APPLIED_PATCHES=${IGNORE_APPLIED_PATCHES:-"False"}

# Get patackage name from patch
# Global vars:
#   OUT - Error or Warning messages
#   PKG - Package name
get_pkg_name_from_patch()
{
    OUT=""
    PKG=""
    local RET=0
    local PATCH=${1:?"Please specify patch's filename"}
    local FILES=$(awk '/\+\+\+/ {print $2}' "${PATCH}")
    # Get Package name and make sure that all affect the only one package
    for FILE in ${FILES}; do
        [ -e "${FILE}" ] || {
            OUT+="[WARN]   ${FILE} skipped since it is absent";
            continue; }
        PACK=$(dpkg -S "${FILE}")
        PACK=$(echo -e "${PACK}" | awk '{print $1}')
        PACK=${PACK/\:/}
        [ -z "${PKG}" ] && {
            PKG="${PACK}";
            continue; }
        [[ "${PACK}" != "${PKG}" ]] && {
            (( RET |= 1 ));
            OUT+="[ERROR]  Affect more than one package: ${PKG} != ${PACK} (${FILE})"; }
    done
    return "${RET}"
}

cd "${PATCHES_DIR}" &>/dev/null || exit 0

HOLD_PKGS=$(apt-mark showhold)

RET=0
# Apply patches
PATCHES=$(find . -type f -name "*.patch" | sort)
for PATCH in ${PATCHES}; do
    cd "${PATCHES_DIR}" || exit 2
    echo -e "\n-------- ${PATCH}"
    get_pkg_name_from_patch "${PATCH}"
    RS=$?
    [ -z "${OUT}"] ||
        echo -e "${OUT}"
    (( RS != 0 ))  && {
        (( RET |= 1 ));
        continue; }
    # Whether package is installed on this node
    [ -z "${PKG}" ] &&
        continue
    # Whether this package should be keeped
    echo "${HOLD_PKGS}" | grep ${PKG} &>/dev/null && {
        echo "[SKIP]   ${PKG} is on hold";
        continue; }

    PATCH_OUT=$(patch -p1 -Nu -r- -d / < "${PATCH}")
    RES=$?
    echo -e "${PATCH_OUT}"
    if (( "${RES}" != 0 )); then
        if [ "${IGNORE_APPLIED_PATCHES,,}" != "true" ]; then
            PATCH_RES=$(grep -E "Skipping|ignored" <<< "${PATCH_OUT}")
            if [ -n "${PATCH_RES}" ]; then
                echo "[ERROR]  Failed to apply ${PATCH}"
                (( RET |= 1 ))
                continue
            fi
        fi
        PATCH_RES=$(grep -Ev "patching|Skipping|ignored" <<< "${PATCH_RES}")
        if [ -n "${PATCH_RES}" ]; then
            echo "[ERROR]  Failed to apply ${PATCH}"
            (( RET |= 2 ))
            continue
        fi
    fi
    echo "[OK]     ${PKG} is customized successfully"
done

exit ${RET}

