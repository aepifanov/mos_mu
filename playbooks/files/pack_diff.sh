#!/bin/bash -x

PACK=${1?:"Please specify package name."}
APT_CONF=${2?:"Please specify apt config file."}

VERS=$(apt-cache policy ${PACK}| awk '/Installed/ {print $2}')
VERS=${VERS/\:/\%3a}

NEW_VERS=$(apt-cache policy ${PACK} | awk '/Candidate/ {print $2}')
NEW_VERS=${NEW_VERS/\:/\%3a}

PYTHON_PACK=${PACK##python-}
PACK_NAME="${PACK}_${VERS}_all.deb"
NEW_PACK_NAME="${PACK}_${NEW_VERS}_all.deb"

CACHED_PACK="/var/cache/apt/archives/${PACK_NAME}"
EXTRACTED_PACK="/tmp/customizations/${PACK}"
INSTALLED_PACK="/usr/lib/python2.7/dist-packages/${PYTHON_PACK}"

DIFF="${EXTRACTED_PACK}/${PACK}_customization.patch"

mkdir -p ${EXTRACTED_PACK}/${VERS}         &&
  cd ${EXTRACTED_PACK}/${VERS}             || exit 1
ar p ${CACHED_PACK} data.tar.xz | tar xJ   || exit 1
diff -c -r -x "*.pyc" ./${INSTALLED_PACK} ${INSTALLED_PACK} > ${DIFF}

mkdir -p ${EXTRACTED_PACK}/${NEW_VERS}     &&
  cd ${EXTRACTED_PACK}/${NEW_VERS}         || exit 1
apt-get -c ${APT_CONF} download ${PACK}
ar p ${NEW_PACK_NAME} data.tar.xz | tar xJ || exit 1

cd ${EXTRACTED_PACK}
patch -p1 -N --dry-run --silent -d ${NEW_VERS} < ${DIFF}
