#!/bin/bash

PKG=${1?:"Please specify package name."}

APT_CONF=${APT_CONF:-$2}
APT_CONF=${APT_CONF:-"/etc/apt/apt.conf"}
CUSTOM_DIR=${CUSTOM_DIR:-$3}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}

PYTHON_PKG=${PKG##python-}
EXTRACTED_PKG="${CUSTOM_DIR}/${PKG}"
INSTALLED_PKG="/usr/lib/python2.7/dist-packages/${PYTHON_PKG}"

POLICY=$(apt-cache -c ${APT_CONF} policy ${PKG}) || exit 1
VERS_ORIG=$(echo -e "${POLICY}" | awk '/Installed/ {print $2}')
VERS=${VERS_ORIG/\:/\%3a}

PKG_FILE="${PKG}_${VERS}_all.deb"
CACHED_PKG_FILE="/var/cache/apt/archives/${PKG_FILE}"

DIFF="${EXTRACTED_PKG}/${PKG}_customization.patch"

# Check if diff already exists
[ -e ${DIFF} ] && exit 0

[ -d ${EXTRACTED_PKG}/${VERS} ] || mkdir -p ${EXTRACTED_PKG}/${VERS}
cd ${EXTRACTED_PKG}/${VERS}     && rm -rf *

if ! [ -e ${CACHED_PKG} ]; then
    apt-get -c ${APT_CONF} download ${PKG}=${VERS_ORIG} || exit 1
    CACHED_PKG_FILE=${PKG_NAME}
fi
ar p ${CACHED_PKG_FILE} data.tar.xz | tar xJ

cd ${EXTRACTED_PKG}
diff -c -r -x "*.pyc" ./${VERS}/${INSTALLED_PKG} ${INSTALLED_PKG} > ${DIFF}
case $? in
    [1])
        exit 0
        ;;
    *)
        exit 1
esac


