#!/bin/bash -x

EXTRACTED_PACK=${MOS_DIR:-"/root/mos_mu"}
INSTALLED_PACK="/usr/lib/python2.7/dist-packages"


cd ${EXTRACTED_PACK} || exit 0

for PACK in $(ls .)
do
  PACK_DIR=${PACK##python-}

  if patch -p0 -N --dry-run -d / < ${PACK}/${PACK}_customization.patch;
  then
    patch -p0 -d / < ${PACK}/${PACK}_customization.patch;
  fi
done
