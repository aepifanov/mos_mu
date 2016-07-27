#!/bin/bash

FUEL_CUSTOM_DIR=${FUEL_CUSTOM_DIR:?"FUEL_CUSTOM_DIR is undefined!"}
FUEL_PATCHES_DIR=${FUEL_PATCHES_DIR:?"FUEL_PATCHES_DIR is undefined!"}

[ -d "$FUEL_CUSTOM_DIR" ] && PATCHES="$(find $FUEL_CUSTOM_DIR -name '*.patch' | rev | cut -d'/' -f1 | rev | sort -u)" || exit 0
FAIL=0
for PATCH in $PATCHES
do
    FILES="$(find $FUEL_CUSTOM_DIR -name "$PATCH")"
    for FILE in $FILES
    do
        MD5="$(grep -v -e '^diff' -e '^---' -e '^+++' "$FILE" | md5sum)"
        FILES_MD5+=$MD5$FILE$'\n'
    done
    UNIQUE_MD5=$(echo "$FILES_MD5" | cut -d' ' -f1 | sort -u | grep -v '^$' | wc -l)
    if [ "$UNIQUE_MD5" -gt 1 ]
    then
        echo "Found inconsistent patch $PATCH. This patch differs across nodes."
        echo "$FILES_MD5"
        FAIL=1
    else
        echo "$FILE"
        [ ! -d "$FUEL_PATCHES_DIR" ] && mkdir -p $FUEL_PATCHES_DIR
        cp $FILE $FUEL_PATCHES_DIR
    fi
done
[ "$FAIL" = 0 ] || exit 1
