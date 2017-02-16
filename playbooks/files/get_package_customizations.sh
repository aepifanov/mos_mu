#!/bin/bash

# For the specified customized package this script generate a patch(diff) file
# between current customized files and original files from installed package
#
# Return:
#     0 - ok
#     x - error

PKG=${1?:"Please specify package name."}
APT_CONF=${APT_CONF:-$2}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
CUSTOM_DIR=${CUSTOM_DIR:-$3}
CUSTOM_DIR=${CUSTOM_DIR:?"CUSTOM_DIR is undefined!"}
KEEP_PKGS=${KEEP_PKGS:-$4}

CACHED_PKG_FILES="/var/cache/apt/archives/"
EXTRACTED_PKG="${CUSTOM_DIR}/${PKG}"
DIFF="${EXTRACTED_PKG}/${PKG}_customization.patch"


# Returns list of cutomized packages based on md5sum util and
# file with MD5 sums file /var/lib/dpkg/info/${PKG}.md5sums
#
# Return:
#     0 - ok
#     x - error
# Global Vars:
# FILES - list of customized files
function md5_verify_md5sum()
{
    FILES=''
    local MD5SUM_FILE="/var/lib/dpkg/info/${PKG}"
    local EXT="md5sums"
    [ -f "${MD5SUM_FILE}.${EXT}" ] || {
        EXT="amd64.md5sums";
    	[ -f "${MD5SUM_FILE}.${EXT}" ] ||
	    return 0;}

    OUT="$(nice -n 19 ionice -c 3 md5sum --quiet -c "${MD5SUM_FILE}.${EXT}" 2>&1)"
    (( $? == 0 )) &&
        return 0
    #exclude packages for which we cannot verify md5sum, no md5sums file
    echo "${OUT}" | grep 'md5sums*No such file' &&
        return -2

    #exclude /etc, .pyc files and md5sum summary lines
    FILES="$(echo "${OUT}" | grep -v '/etc/\|\.pyc\|md5sum:')"
    [ -n "${FILES}" ]  && {
	FILES=$(echo "${FILES}" | awk '{gsub(/\:/,"");print "/"$1}');}

    return 0
}

# Returns list of cutomized packages based on dpkg --verify (if it available) or
# or by calling md5_verify_md5sum()
#
# Return:
#     0 - ok
#     x - error
# Global Vars:
# FILES - list of customized files
function md5_verify ()
{
    OUT=$(nice -n 19 ionice -c 3 dpkg -V "${PKG}" 2>/dev/null)
    if (( $? == 0 )); then
    	FILES=$(echo "${OUT}" |  awk '{if ($2 != "c") print $2}')
    else
	md5_verify_md5sum "${PKG}" ||
	    return $?
    fi
    return 0
}

# Returns a path to the deb file of specified package and version
#
# Return:
#     0 - ok
#     x - error
# Global Vars:
# PKG_FILE - deb file for required package and version
function get_deb ()
{
    local PKG=${1:?"Please specify package name."}
    local VERS=${2:?"Please specify package version"}

    # Try to find required deb file in cached directory
    PKG_FILE=$(find "${CACHED_PKG_FILES}" -type f -name "${PKG}*${VERS##*:}*.deb")
    [ -f "${PKG_FILE}" ] && return 0

    # Download required deb file from repository
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


HOLD_PKGS=$(apt-mark showhold)
echo "${KEEP_PKGS} ${HOLD_PKGS}" | grep ${PKG} &&
    exit 100

POLICY=$(apt-cache -c "${APT_CONF}" policy "${PKG}") || exit -1
VERS=$(echo -e "${POLICY}" | awk '/Installed/ {print $2}')

RET=0

# Check if diff already exists
[ -f "${DIFF}" ] &&
    exit 0

[ -d "${EXTRACTED_PKG}/${VERS}" ] ||
    mkdir -p "${EXTRACTED_PKG}/${VERS}"
cd "${EXTRACTED_PKG}/${VERS}" &&
    rm -rf ./*

get_deb "${PKG}" "${VERS}"

unpack_deb "${PKG_FILE}" || exit -1

cd /
md5_verify "${PKG}" || exit -1

cd "${EXTRACTED_PKG}" || exit -1

for FILE in ${FILES}; do
    file "${FILE}" | grep text &> /dev/null || {
        echo "[WARN] File ${FILE} is not text and will be ignored and might replaced during the update procedure";
        continue; }
    diff -NrU 5 "./${VERS}/${FILE}" "${FILE}" >> "${DIFF}"
    case $? in
        1)
            ;;
        *)
            (( RET |= 1 ))
            ;;
    esac
done

exit "${RET}"
