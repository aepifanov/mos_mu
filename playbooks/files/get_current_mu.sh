#!/bin/bash

REL="Undefined"

APT_DIR=${1:-$APT_DIR}
APT_DIR=${APT_DIR:?"APT_DIR is undefined!"}
APT_CONF=${2:-$APT_CONF}
APT_CONF=${APT_CONF:?"APT_CONF is undefined!"}

APT_SOURCE="${APT_DIR}/sources.list.d"

REPOS=$(find "${APT_SOURCE}" -type f -name "*.list")
for REPO in ${REPOS}; do
	apt-get  -c "${APT_CONF}" -o Dir::Etc::sourcelist="${REPO}"  -o Dir::Etc::sourceparts="-"  --just-print upgrade | grep Inst &>/dev/null ||
		{ REL="${REPO}";
		break; };
done

REL=${REL##*/}
REL=${REL%%.list}

echo "${REL}"
