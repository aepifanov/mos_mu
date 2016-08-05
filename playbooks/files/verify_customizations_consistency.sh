#!/bin/bash

FUEL_CUSTOM_DIR=${1:-$FUEL_CUSTOM_DIR}
FUEL_CUSTOM_DIR=${FUEL_CUSTOM_DIR:?"FUEL_CUSTOM_DIR is undefined!"}
FUEL_PATCHES_DIR=${2:-$FUEL_PATCHES_DIR}
FUEL_PATCHES_DIR=${FUEL_PATCHES_DIR:?"FUEL_PATCHES_DIR is undefined!"}

PROCESSED_DIR="processed"
FUEL_PROCESSED_DIR="${FUEL_CUSTOM_DIR}/${PROCESSED_DIR}"
FUEL_UNIQUE_DIR="${FUEL_PROCESSED_DIR}/unique"
FUEL_RESULT="${FUEL_PROCESSED_DIR}/result.txt"

cd "${FUEL_CUSTOM_DIR}" || exit 0
ALL_NODES=$(ls | grep -v "${PROCESSED_DIR}" | sort)

mkdir -p "${FUEL_PROCESSED_DIR}"
rm -rf "${FUEL_PROCESSED_DIR}"/*

for NODE in ${ALL_NODES}; do
    cd ${FUEL_CUSTOM_DIR}/${NODE}
    for PATCH in *.patch; do
        [ -e "${PATCH}" ] || continue
        PKG=${PATCH%%_*.patch}
        mkdir -p "${FUEL_PROCESSED_DIR}/${PKG}/${NODE}"
        cp "${PATCH}" "${FUEL_PROCESSED_DIR}/${PKG}/${NODE}"
    done
done

cd "${FUEL_PROCESSED_DIR}" || exit 0
ALL_PKGS=$(ls | sort)


MD5_ARRAY=()
get_array_id_for_md5()
{
    local i=0
    MD5=${1:?"No MD5"}
    ARRAY_SIZE=${#MD5_ARRAY[@]}
    for ((i=0; i<${ARRAY_SIZE}; i++)); do
        if [ $MD5 == ${MD5_ARRAY[$i]} ]; then
            return $i
        fi
    done
    MD5_ARRAY[$i]=${MD5}
    return $i
}

RET=0
set_return_code()
{
    NEW_RET=$1
    [ -z "${NEW_RET}" ] && return 0
    (( "${NEW_RET}" > "${RET}")) && { RET="${NEW_RET}"; }
}

ARRAY=()
imax=$(echo ${ALL_PKGS} | wc -w)
jmax=$(echo ${ALL_NODES} | wc -w)
i=0 #PKG
for PKG in ${ALL_PKGS}; do
    MD5_ARRAY=()
    cd "${FUEL_PROCESSED_DIR}/${PKG}"
    j=0 #NODE
    for NODE in ${ALL_NODES}; do
        if [ ! -d ${NODE} ]; then
            ARRAY[$i+$j*$imax]="-"
            set_return_code 1
        else
            FILE_PATCH="${NODE}/${PKG}_customization.patch"
            MD5="$(grep -v -e '^diff' -e '^---' -e '^+++' "${FILE_PATCH}" | md5sum | awk '{print $1}')"
            get_array_id_for_md5 ${MD5}
            ID=$?
            ARRAY[$i+$j*$imax]=${ID}
        fi
        ((j++))
    done
    if (( ${#MD5_ARRAY[*]} > 1 )); then
        set_return_code 2
    fi
    ((i++))
done

OUT="nodes/packages $(echo ${ALL_PKGS})\n"
j=0 #NODE
for NODE in ${ALL_NODES}; do
    LINE="${NODE}"
    i=0 #PKG
    for PKG in ${ALL_PKGS}; do
        LINE+=" ${ARRAY[$i+$j*$imax]}"
        ((i++))
    done
    ((j++))
    OUT+="${LINE}\n"
done

echo -e "Legenda:
 '-' - no patch(customizations) for package on this node
 'x' - ID of patch\n"
echo -e "${OUT}" | column -t

exit ${RET}
