#!/bin/bash

# This script tries to apply  all patches from ${PATCHES_DIR} directory
# on the specified (${PKG_VER_FOR_VERIFICATION}) version of packages
# (Installed or Candidate)
#
# Return:
#     0 - ok
#     x - error
# Output:
#     Result of verification

APT_CONF=${1:-$APT_CONF}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
PATCHES_DIR=${2:-$PATCHES_DIR}
PATCHES_DIR=${PATCHES_DIR:?"PATCHES_DIR is undefined!"}
VERIFICATION_DIR=${3:-$VERIFICATION_DIR}
VERIFICATION_DIR=${VERIFICATION_DIR:?"VERIFICATION_DIR is undefined!"}
PKG_VER_FOR_VERIFICATION=${4:-$PKG_VER_FOR_VERIFICATION}
PKG_VER_FOR_VERIFICATION=${PKG_VER_FOR_VERIFICATION:?"PKG_VER_FOR_VERIFICATION is undefined!"}
IGNORE_APPLIED_PATCHES=${5:-$IGNORE_APPLIED_PATCHES}
IGNORE_APPLIED_PATCHES=${IGNORE_APPLIED_PATCHES:-"False"}
KEEP_PKGS=${KEEP_PKGS:-$6}

CACHED_PKG_FILES="/var/cache/apt/archives/"

# Gets patackage name from patch
#
# Return:
#     0 - ok
#     x - error
# Global vars:
#   OUT - Error or Warning messages
#   PKG - Package name
get_pkg_name_from_patch()
{
    OUT=""
    PKG=""
    local RET=0
    local PATCH=${1:?"Please specify patch's filename"}

    # Get list of customized files from patch file
    local FILES=$(awk '/\+\+\+ \// {print $2}' "${PATCH}")
    # Make sure that all customized files are belonged to the same Package
    for FILE in ${FILES}; do
        [ -f "${FILE}" ] || {
            OUT+="[WARN]   ${FILE} skipped since it is absent\n";
            continue; }
        PACK=$(dpkg -S "${FILE}")
        PACK=$(echo -e "${PACK}" | awk '{print $1}')
	# Make sure that this file isn't belonged to the several packages
        [[ "${PACK}" =~ .*diversion*. ]] && {
            (( RET |= 1 ));
            OUT+="[ERROR]  File ${FILE} is diversion\n";
            continue; }
        PACK=${PACK/\:/}
        [ -z "${PKG}" ] && {
            PKG="${PACK}";
            continue; }
        [[ "${PACK}" != "${PKG}" ]] && {
            (( RET |= 1 ));
            OUT+="[ERROR]  Affect more than one package: ${PKG} != ${PACK} (${FILE})\n";
	    continue; }
    done
    return "${RET}"
}

# Returns a path to the deb file of specified package and version
#
# Return:
#     0 - ok
#     x - error # Global Vars:
# Global Vars:
# PKG_FILE - deb file for required package and version
function get_deb ()
{
    local PKG=${1:?"Please specify package name."}
    local VERS=${2:?"Please specify package version"}
    PKG_FILE=$(find "${CACHED_PKG_FILES}" -type f -name "${PKG}*${VERS##*:}*.deb")
    [ -f "${PKG_FILE}" ] && return 0

    apt-get -c "${APT_CONF}" download "${PKG}=${VERS}" &> /dev/null || return -1
    PKG_FILE=$(find . -type f -name "${PKG}*${VERS##*:}*.deb")
    [ -f "${PKG_FILE}" ] && return 0

    return 1
}

# Unpacks specified deb file
#
# Return:
#     0 - ok
#     x - error
function unpack_deb ()
{
    local PKG_FILE=${1:?"Please specify package name."}
    [ -f "${PKG_FILE}" ] || return -1
    local DATA=$(ar t "${PKG_FILE}" | grep data.tar)
    local ARCH_KEY=''
    case $(echo "${DATA}" | awk -F '.' '{print $3}') in
	'gz')
	    ARCH_KEY='z'
	    ;;
	'xz')
	    ARCH_KEY='J'
            ;;
	*)
	    return -2
	    ;;
    esac
    ar p "${PKG_FILE}" "${DATA}" | tar x"${ARCH_KEY}" || return -3
}


cd "${PATCHES_DIR}" &>/dev/null || exit 0

HOLD_PKGS=$(apt-mark showhold)

RET=0
# Check patches
PATCHES=$(find . -type f -name "*.patch" |sort)
for PATCH in ${PATCHES}; do
    cd "${PATCHES_DIR}" || exit -1
    echo -e "\n-------- ${PATCH}"
    get_pkg_name_from_patch "${PATCH}"
    RS=$?
    [ -n "${OUT}" ] &&
        echo -e "${OUT}"
    (( RS != 0 ))  && {
        (( RET |= 1 ));
        continue; }
    # Whether package is installed on this node ?
    [ -z "${PKG}" ] &&
        continue
    # Whether this package should be keeped ?
    echo "${KEEP_PKGS} ${HOLD_PKGS}" | grep ${PKG} &>/dev/null  && {
        echo "[SKIP]   ${PKG} is on hold";
        continue; }

    # Identify required version
    EXTRACTED_PKG=${VERIFICATION_DIR}/${PKG}
    POLICY=$(apt-cache -c "${APT_CONF}" policy "${PKG}" 2>/dev/null ) || exit -1
    VERS=$(echo -e "${POLICY}" | grep "${PKG_VER_FOR_VERIFICATION}" | awk '{print $2}')

    [ -d "${EXTRACTED_PKG}/${VERS}" ] ||
        mkdir -p "${EXTRACTED_PKG}/${VERS}"
    cd "${EXTRACTED_PKG}/${VERS}" &&
        rm -rf ./*

    get_deb "${PKG}" "${VERS}"

    unpack_deb "${PKG_FILE}" || exit -1

    # Verify patch applying
    cd "${EXTRACTED_PKG}" || exit -1

    cp -f "${PATCHES_DIR}/${PATCH}" .
    PATCH_FILENAME=${PATCH##*/}
    PATCH_OUT=$(patch -p1 -Nu -r- -d "${VERS}" < "${PATCH_FILENAME}")
    RES=$?
    echo -e "${PATCH_OUT}"
    if (( RES != 0 )); then
        if [ "${IGNORE_APPLIED_PATCHES,,}" != "true" ]; then
            PATCH_RES=$(grep -E "Skipping|ignored" <<< "${PATCH_OUT}")
            if [ -n "${PATCH_RES}" ]; then
                echo "[ERROR]  Failed to apply ${PATCH}"
                (( RET |= 4))
                continue
            fi
        fi
        # FIXME: Need to be tested and modified !?
        # Only the following lines should present in output:
        #    patching file usr/lib/python2.7/dist-packages/......
        #    Reversed (or previously applied) patch detected!  Skipping patch.
        #    2 out of 2 hunks ignored
        PATCH_RES=$(grep -Ev "patching|Skipping|ignored" <<< "${PATCH_OUT}")
        if [ -n "${PATCH_RES}" ]; then
            echo "[ERROR]  Failed to apply ${PATCH}"
            (( RET |= 8))
            continue
        fi
    fi
    echo "[OK]     ${PKG} is customized successfully"
done

if (( (RET & 4) == 4 )); then
    echo ""
    echo "Some patches look as already applied."
    echo "Please make sure that these patches were included in MU"
    echo "If you sure that it is, you can use the following flag:"
    echo ' {"ignore_applied_patches":true}'
    echo "for ignoring these patches."
fi
if (( (RET & 8) == 8 )); then
    echo ""
    echo "Some patches failed to apply."
    echo "Please resolve this issue:"
    echo " 1. Go on the failed nodes in 'verification' folder"
    echo " 2. Handle the issue with patch applying."
    echo " 3. Copy this patch  to 'patches' folder"
    echo ' 4. use -e {"use_current_customizations":false} for skipping'
    echo "    verification and using of gathered customizations."
fi

exit "${RET}"
