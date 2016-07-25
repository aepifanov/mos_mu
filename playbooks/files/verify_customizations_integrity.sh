#!/bin/bash

PKG=${1?:"Please specify package name."}
FUEL_CUSTOM_DIR=${FUEL_CUSTOM_DIR:?"FUEL_CUSTOM_DIR is undefined!"}

PATCHES="$(find $FUEL_CUSTOM_DIR -name '*.patch' | sort -u)"
for PATCH in "$PATCHES"
do
    BASENAME="$(echo $PATCH | rev | cut -d'/' -f1 | rev)"
    FILES_MD5="$(find $FUEL_CUSTOM_DIR -name '$BASENAME' -exec md5sum {} \;)"
    UNIQUE_MD5="$(echo $FILES_MD5 | cut -d' ' -f1 | sort -u | wc -l)"
    if [ "$UNIQUE_MD5" -gt 1 ]
    then
        echo "Found non-uniform patches for package $PKG!"
        echo "$FILES_MD5"
        exit 1
    fi
done
