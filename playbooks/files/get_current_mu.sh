#!/bin/bash

REL=""

APT_CONF=${1:-$APT_CONF}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
APT_SRC_DIR=${2:-$APT_SRC_DIR}
APT_SRC_DIR=${APT_SRC_DIR:-"/root/mos_mu/apt/sources.list.d"}

OUTS="\n"
REPOS=$(find "${APT_SRC_DIR}" -type f -name "*.list")
for REPO in ${REPOS}; do
    OUT=$(apt-get  -c "${APT_CONF}" -o Dir::Etc::sourcelist="${REPO}"  -o Dir::Etc::sourceparts="-"  --just-print upgrade)
    REPO=${REPO##*/}
    REPO=${REPO%%.list}
    OUTS+="${REPO}:\n"
    OUTS+="    $(echo -e "${OUT}" | grep "upgraded,")\n"
    echo "${OUT}" | grep Inst &>/dev/null || {
	[ -n "${REL}" ] && {
	    REL+=", "; };
	REL+="${REPO}"; }
done

REL=${REL##*/}
REL=${REL%%.list}

if [ -n "${REL}" ]; then
    echo "${REL}"
else
    echo "Undefined"
    echo -e "${OUTS}"
fi
