#!/bin/bash

# This script
# - make
#     apt-get -c $1 update
# - for each upgradable package verify md5 sum
# - return:
#     0 - ok
#     1 - some packets were installed not from configured repositories
#     2 - some other error
# - output:
#     list of customized packages and undentified packages

APT_CONF=${APT_CONF:-$1}
APT_CONF=${APT_CONF:-"/etc/apt/apt.conf"}


function md5_verify()
{
    PKG=${1:?"Please specify package name."}

    cd / || return 2

    if [ -f "/var/lib/dpkg/info/${PKG}:amd64.md5sums" ]
    then
        result="$(nice -n 19 ionice -c 3 md5sum --quiet -c /var/lib/dpkg/info/"${PKG}":amd64.md5sums 2>&1)"
    else
        result="$(nice -n 19 ionice -c 3 md5sum --quiet -c /var/lib/dpkg/info/"${PKG}".md5sums 2>&1)"
    fi

    test $? -eq 0 && return 0

    #exclude packages for which we cannot verify md5sum, no md5sums file
    if [ "$(echo "$result" | grep md5sums | grep -c 'No such file')" -gt 0 ]
    then
        return 3
    fi

    #exclude ./etc (elasticsearch packaging issue)
    result="$(echo "$result" | grep -v '^\./etc/')"

    #exclude .pyc files
    result="$(echo "$result" | grep -v '\.pyc$')"

    #exclude bad formatted / empty md5sum files and md5sum summary lines
    result="$(echo "$result" | grep -v 'did NOT match\|md5sum: ')"
    if [ -n "$result" ]
    then
        return 1
    fi
    return 2
}

RET=0
PKGS=$(apt-get -c "${APT_CONF}" --just-print upgrade) || exit 2

for PKG in $(echo "${PKGS}" | awk '/Conf/ {print $2}'); do
    # We will work only with python packages
    PKG=$(echo "${PKG}" | grep "python-") || continue

    PKG_POLICY=$(apt-cache -c "${APT_CONF}" policy "${PKG}") || exit 2
    echo "${PKG_POLICY}" | grep "\*\*\*" -A1 | grep Packages &> /dev/null
    if [ ! $? ]; then
        echo "Undentified package: \"${PKG}\" was installed not from the configured repositories."
        RET=1
        continue
    fi

    md5_verify "${PKG}"
    if (( $? == 1 )); then
        echo "${PKG}"
    fi
done

exit "${RET}"

