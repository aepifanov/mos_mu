VERIFICATION#!/bin/bash


# Return:
# 0 - Ok
# 1 - Some packages customized not on all nodes
# 2 - Some packages have different customizations on different nodes

FUEL_CUSTOM_DIR=${1:-$FUEL_CUSTOM_DIR}
FUEL_CUSTOM_DIR=${FUEL_CUSTOM_DIR:?"FUEL_CUSTOM_DIR is undefined!"}
FUEL_PATCHES_DIR=${2:-$FUEL_PATCHES_DIR}
FUEL_PATCHES_DIR=${FUEL_PATCHES_DIR:?"FUEL_PATCHES_DIR is undefined!"}
FUEL_VERIFICATION_DIR=${3:-$FUEL_VERIFICATION_DIR}
FUEL_VERIFICATION_DIR=${FUEL_VERIFICATION_DIR:?"FUEL_VERIFICATION_DIR is undefined!"}
FUEL_UNIFIED_DIR=${4:-$FUEL_UNIFIED_DIR}
FUEL_UNIFIED_DIR=${FUEL_UNIFIED_DIR:?"FUEL_UNIFIED_DIR is undefined!"}
UNIFY_ONLY_PATCHES=${5:-$UNIFY_ONLY_PATCHES}
UNIFY_ONLY_PATCHES=${UNIFY_ONLY_PATCHES:-"FALSE"}

FUEL_RESULT="${FUEL_VERIFICATION_DIR}/result.txt"


cd "${FUEL_CUSTOM_DIR}" || exit 0
ALL_NODES=$(ls | sort)

mkdir -p "${FUEL_VERIFICATION_DIR}"
rm -rf "${FUEL_VERIFICATION_DIR}"/*

mkdir -p "${FUEL_UNIFIED_DIR}"
rm -rf "${FUEL_UNIFIED_DIR}"/*

for NODE in ${ALL_NODES}; do
    cd ${FUEL_CUSTOM_DIR}/${NODE}
    for PATCH in *.patch; do
        [ -e "${PATCH}" ] || continue
        PKG=${PATCH%%_*.patch}
        mkdir -p "${FUEL_VERIFICATION_DIR}/${PKG}/${NODE}"
        cp "${PATCH}" "${FUEL_VERIFICATION_DIR}/${PKG}/${NODE}"
    done
done


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


cd "${FUEL_VERIFICATION_DIR}" || exit 0
ALL_PKGS=$(ls | sort)
# If no customizations exit
[ -z ${ALL_PKGS} ] && exit 0

RET=0
ARRAY=()
imax=$(echo ${ALL_PKGS} | wc -w)
jmax=$(echo ${ALL_NODES} | wc -w)
i=0 #PKG
for PKG in ${ALL_PKGS}; do
    MD5_ARRAY=()
    cd "${FUEL_VERIFICATION_DIR}/${PKG}"
    j=0 #NODE
    for NODE in ${ALL_NODES}; do
        if [ ! -d ${NODE} ]; then
            ARRAY[$i+$j*$imax]="-"
            let "RET|=1"
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
        let "RET|=2"
    fi
    ((i++))
done

i=0 #PKG
for PKG in ${ALL_PKGS}; do
    j=0 #NODE
    ST=0
    cd "${FUEL_VERIFICATION_DIR}/${PKG}"
    FILE_PATCH=$(find . -type f -name "*.patch" | head -n 1)
    [ -e "${FILE_PATCH}" ] ||
        continue
    for NODE in ${ALL_NODES}; do
        case ${ARRAY[$i+$j*$imax]} in
            0)
                ;;
            '-')
                let "ST|=1"
                ;;
            *)
                let "ST|=2"
        esac
        ((j++))
    done
    case ${ST} in
        0)
            cp "${FILE_PATCH}" "${FUEL_UNIFIED_DIR}"
            ;;
        1)
            if [ "${UNIFY_ONLY_PATCHES,,}" == "true" ]; then
                cp "${FILE_PATCH}" "${FUEL_UNIFIED_DIR}"
            fi
    esac
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


if [ "${UNIFY_ONLY_PATCHES,,}" == "true" ]; then
    (( ${RET} == 1 )) &&
        RET=0
fi

if (( (${RET}&1) == 1 )); then
    echo ""
    echo "Some packages customized not on all nodes."
    echo "Please make sure that these customizations are correct and"
    echo "than you can use the following flag:"
    echo '-e {"unify_only_patches":true}'
fi
if (( (${RET}&2) == 2 )); then
    echo ""
    echo "Some packages have different customizations on different nodes."
    echo "Please resolve this issue:"
    echo " 1. Identify which customization should be used"
    echo " 2. Copy them to 'patches' folder"
    echo ' 3. use -e {"use_current_customizations":false} for skipping'
    echo "    verification and using of gathered customizations."
fi

exit ${RET}
