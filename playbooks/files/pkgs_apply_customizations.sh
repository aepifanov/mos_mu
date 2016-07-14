#!/bin/bash

CUSTOM_DIR=${1:-$CUSTOM_DIR}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}
PATCHES_DIR=${2:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}

prepare_current_customizations_for_applying()
{
    cd ${CUSTOM_DIR} || return 0
    [ ! -d ${PATCHES_DIR} ] || mkdir -p ${PATCHES_DIR}
    for PACK in *; do
        cp ${PACK}/${PACK}_customization.patch ${PATCHES_DIR}
    done
}

SKIP_USE_CURRENT_CUSTOMIZATIONS=${SKIP_USE_CURRENT_CUSTOMIZATIONS:-"false"}
[ ! ${SKIP_USE_CURRENT_CUSTOMIZATIONS} ] &&
    prepare_current_customizations_for_applying

cd ${PATCHES_DIR} || exit 0

RET=0
SKIPPED_PATCHES=""

# Check patches
for PATCH in *.patch; do
    FILES=$(grep 'diff' -A3 ${PATCH} | awk '/\-\-\-/ {print $2}')
    PKG=""
    # Get Package name and make sure that all affect the only one package
    for FILE in ${FILES}; do
        PACK=$(dpkg -S ${FILE}) || {
            echo "[WARN] ${PATCH} will be skipped since target file '${FILE}' is absent";
            SKIPPED_PATCHES="${SKIPPED_PATCHES} ${PATCH}"
            break; }
        PACK=$(echo ${PACK} | awk '{print $1}')
        PACK=${PACK#:}
        [ -z ${PKG} ] && { PKG=${PACK}; continue; }
        [[ ${PACK} == ${PKG} ]] && continue
        echo "[ERROR] ${PATCH} affects more than one package"
        RET=1
        break
    done

    # Download new version and extract it
    NEW_VERS_ORIG=$(apt-cache policy ${PACK} | awk '/Candidate/ {print $2}')
    NEW_VERS=${NEW_VERS_ORIG/\:/\%3a}
    NEW_VERS_PATH=${CUSTOM_DIR}/${PKG}/${NEW_VERS}

    PYTHON_PKG=${PKG##python-}
    NEW_PKG_NAME="${PKG}_${NEW_VERS}_all.deb"

    mkdir -p ${NEW_VERS_PATH}     &&
        cd ${NEW_VERS_PATH}       &&
        rm -rf *                  || { RET=2; continue; }
    apt-get -c ${APT_CONF} download ${PKG}
    ar p ${NEW_PACK_NAME} data.tar.xz | tar xJ || { RET=2; continue; }

    # Dry-run apply patch
    CACHED_PACK="/var/cache/apt/archives/${PKG}"
    patch -p0 -N --dry-run -d  < ${PATCH} || {
        echo "[ERROR] ${PATCH} failed to apply"
        RET=1; }
done


[ ! ${RET} ] && exit 1

SKIP_APPLY_PATCHES=${SKIP_APPLY_PATCHES:-"false"}
[[ ${SKIP_APPLY_PATCHES,,} == "true" ]] && exit ${RET}

# Apply patches
for PATCH in *.patch; do
    [[ ${SKIPPED_PATCHES} == *${PATCH}* ]] && continue

    patch -p0 -d / < ${PATCH} || RET=1
done

exit ${RET}

