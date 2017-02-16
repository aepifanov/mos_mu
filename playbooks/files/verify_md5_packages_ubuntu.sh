#!/bin/bash

# This script verifies MD5 sum for all installed packages
#
# Return:
#     0 - ok
#     x - error
# Output:
#     List of customized and unidentified packages


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


# Get list of all installed packages and check md5 sum for them
CUSTOMIZED_PKGS=""
ALL_PKGS=$(dpkg-query -W -f='${Package}\n') || exit -1
cd /

# Verify all installed packages one by one
for PKG in ${ALL_PKGS}; do
    md5_verify "${PKG}" || exit -1
    if [ -n "${FILES}" ]; then
        # Add to customized packages
        [ -n "${CUSTOMIZED_PKGS}" ] &&
            CUSTOMIZED_PKGS+="\n"
        CUSTOMIZED_PKGS+="${PKG}"
   fi
done

[ -n "${CUSTOMIZED_PKGS}" ] &&
    echo -e "${CUSTOMIZED_PKGS}"

exit 0
