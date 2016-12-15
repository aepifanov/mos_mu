#!/bin/bash

# This script verifies MD5 sum for all installed packages
# Return:
#     0 - ok
# Output:
#     List of customized packages and unidentified packages

# Return:
#     0 - ok
#     1 - installed package was customized
#     x - some other error
function md5_verify()
{
    PKG=${1:?"Please specify package name."}
    cd / || return 2

    RESULT=$(nice -n 19 ionice -c 3 dpkg -V "${PKG}")
    (( $? != 0 )) &&
        return 2
    RESULT=$(echo -e "${RESULT}" | awk '{if ($2 != "c") print $2}')
    [ -n "${RESULT}" ]  &&
        return 1
    return 0
}


# Get list of all installed packages and check md5 sum for them
CUSTOMIZED_PKGS=""
ALL_PKGS=$(dpkg-query -W -f='${Package}\n') || exit -1

RET=0
for PKG in ${ALL_PKGS}; do
    md5_verify "${PKG}"
    case $? in
        0)
            ;;
        1)
            # Add to customized packages
            [[ "${CUSTOMIZED_PKGS}" != "" ]] &&
                CUSTOMIZED_PKGS+="\n"
            CUSTOMIZED_PKGS+="${PKG}"
            ;;
        *)
            (( RET |= 1 ))
            ;;
    esac
done

[ -z "${CUSTOMIZED_PKGS}" ] || echo -e "${CUSTOMIZED_PKGS}"
