#!/bin/bash

APT_CONF=${1:-$APT_CONF}
APT_CONF=${APT_CONF:?"APT_CONF is undefined!"}
PATCHES_DIR=${2:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}
VERIFICATION_DIR=${3:-$VERIFICATION_DIR}
VERIFICATION_DIR=${VERIFICATION_DIR:?"VERIFICATION_DIR is undefined!"}

cd ${PATCHES_DIR} || exit 0

RET=0
# Check patches
for PATCH in *.patch; do
    cd ${PATCHES_DIR}
    FILES=$(grep 'diff' -A3 ${PATCH} | awk '/\-\-\-/ {print $2}')
    PKG=""
    # Get Package name and make sure that all affect the only one package
    for FILE in ${FILES}; do
        PACK=$(dpkg -S ${FILE}) || {
            echo "[WARN] ${PATCH} will be skipped since target file '${FILE}' is absent";
            rm "${PATCH}"
            break; }
        PACK=$(echo -e ${PACK} | awk '{print $1}')
        PACK=${PACK/\:/}
        [ -z ${PKG} ] && { PKG=${PACK}; continue; }
        [[ ${PACK} == ${PKG} ]] && continue
        echo "[ERROR] ${PATCH} affects more than one package"
        RET=1
        break
    done

    # Download new version and extract it
    PKG_PATH=${VERIFICATION_DIR}/${PKG}
    POLICY=$(apt-cache -c ${APT_CONF} policy ${PKG}) || exit 1
    VERS_ORIG=$(echo -e "${POLICY}" | awk '/Candidate/ {print $2}')
    VERS=${VERS_ORIG/\:/\%3a}
    VERS_PATH=${PKG_PATH}/${VERS}
    PKG_NAME="${PKG}_${VERS}_all.deb"

    [ -d ${VERS_PATH} ] || mkdir -p ${VERS_PATH}
    cd ${VERS_PATH}
    [ -e ${PKG_NAME} ] ||
        apt-get -c ${APT_CONF} download ${PKG} ||
	    { RET=2; continue; }
    [ -d "usr" ] ||
        ar p ${PKG_NAME} data.tar.xz | tar xJ ||
    	    { RET=2; continue; }

    # Dry-run apply patch
    cd ${PKG_PATH}
    cp -f ${PATCHES_DIR}/${PATCH} .
    patch -p1 -N -d ${VERS} < ${PATCH} ||
        { echo "[ERROR] ${PATCH} failed to apply"; RET=1; }
done

exit ${RET}
