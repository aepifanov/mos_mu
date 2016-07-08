#!/bin/bash

function md5_verify()
{
    PGK=${1:?"Please specify package name."}
    if [ -f "/var/lib/dpkg/info/${PKG}:amd64.md5sums" ]
    then
        result="$(cd /; nice -n 19 ionice -c 3 md5sum --quiet -c /var/lib/dpkg/info/${PKG}:amd64.md5sums 2>&1)"
    else
        result="$(cd /; nice -n 19 ionice -c 3 md5sum --quiet -c /var/lib/dpkg/info/${PKG}.md5sums 2>&1)"
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
        #echo -e "$result" | sed "s|^|$l\t|"
        return 1
    fi
    return 2
}

APT_CONF=${1:-"/etc/apt/apt.conf"}

CUSTOM_PACKAGES=""
RET=0
for PKG in $(apt-get -c ${APT_CONF} --just-print upgrade | awk '/Conf/ {print $2}' ); do
    apt-cache -c ${APT_CONF} policy ${PKG} | grep "\*\*\*" -A1 | grep Packages &> /dev/null
    if (( $? != 0 ))
    then
        echo "Packet ${PKG} was installed not from the configured repositories."
        RET=1
        continue
    fi
    md5_verify ${PKG}
    if (( $? == 1 ))
    then
        echo ${PKG}
    fi
done
#test ${RET} && echo -e "${CUSTOM_PACKAGES}"
exit ${RET}

