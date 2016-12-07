#!/bin/bash

# This script verifies MD5 sum for all installed packages
# Return:
#     0 - ok
#     1 - some customized packets were installed not from configured repositories
#     2 - some upgradable packets were installed not from configured repositories
#     3 - some other error
# Output:
#     List of customized packages and unidentified packages
APT_CONF=${APT_CONF:-$1}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
UNKNOWN_CUSTOM_PKGS=${UNKNOWN_CUSTOM_PKGS:-$2}
UNKNOWN_CUSTOM_PKGS=${UNKNOWN_CUSTOM_PKGS:-"fail"}
UNKNOWN_UPGRADABLE_PKGS=${UNKNOWN_UPGRADABLE_PKGS:-$3}
UNKNOWN_UPGRADABLE_PKGS=${UNKNOWN_UPGRADABLE_PKGS:-"fail"}

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
            PKG_POLICY=$(apt-cache -c "${APT_CONF}" policy "${PKG}") || exit -1
            echo "${PKG_POLICY}" | grep -F "***" -A1 | grep Packages &> /dev/null
            if [ $? != 0 ]; then
                case ${UNKNOWN_CUSTOM_PKGS,,} in
                    "keep")
                        echo "[KEEP] Unknown customized package '${PKG}' will be kept."
                        apt-mark hold "${PKG}" &> /dev/null
                        ;;
                    "reinstall")
                        echo "[REINSTALL] Unknown customized package '${PKG}' will be reinstalled on the available version."
                        ;;
                    *)
                        echo "[ERROR] Unknown customized package: \"${PKG}\" was installed not from the configured repositories."
                        (( RET |= 1 ))
                        ;;
                esac
                continue
            fi

            # Add to customized packages
            [[ "${CUSTOMIZED_PKGS}" != "" ]] &&
                CUSTOMIZED_PKGS+="\n"
            CUSTOMIZED_PKGS+="${PKG}"
            ;;
        *)
            (( RET |= 2 ))
            ;;
    esac
done

# Make sure that all upgradable packages were installed from configured repos
ALL_PKGS=$(apt-get -c "${APT_CONF}" --just-print upgrade | grep "Inst" | awk '{print $2}' ) || exit -1
for PKG in ${ALL_PKGS}; do
    PKG_POLICY=$(apt-cache -c "${APT_CONF}" policy "${PKG}") || exit -1
    echo "${PKG_POLICY}" | grep -F "***" -A1 | grep Packages &> /dev/null
    if [ $? != 0 ]; then
        case ${UNKNOWN_UPGRADABLE_PKGS,,} in
            "keep")
                echo "[KEEP] Unknown upgradable package '${PKG}' will be kept."
                apt-mark hold "${PKG}" &> /dev/null
                ;;
            "reinstall")
                echo "[REINSTALL] Unknown upgradable package '${PKG}' will be reinstalled on the new available version."
                ;;
            *)
                echo "[ERROR] Unknown upgradable package: '${PKG}' was installed not from the configured repositories."
                (( RET |= 2 ))
                ;;
        esac
    fi
done

[ -z "${CUSTOMIZED_PKGS}" ] || echo -e "${CUSTOMIZED_PKGS}"

if (( (RET & 1) == 1 )); then
    echo ""
    echo "Some customized packages were installed not from the"
    echo "configured repositories. So customizations will not be"
    echo "gathered from these packages."
    echo "For the solving this situation you can use the following variable:"
    echo '-e {"unknown_custom_pkgs":"<action>"}'
    echo "Please choose one of the following actions:"
    echo " - fail"
    echo " - keep"
    echo " - reinstall"
fi
if (( (RET & 2) == 2 )); then
    echo ""
    echo "Some upgradable packages were installed not from the"
    echo "configured repositories."
    echo "For the solving this situation you can use the following variable:"
    echo '-e {"unknown_upgradable_pkgs":"<action>"}'
    echo "Please choose one of the following actions:"
    echo " - fail"
    echo " - keep"
    echo " - reinstall"
fi
exit "${RET}"

