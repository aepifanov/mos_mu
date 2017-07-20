#!/bin/bash

APT_CONF=${1:-$APT_CONF}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
APT_FLAGS=${2:-$APT_FLAGS}
APT_FLAGS=${APT_FLAGS:-""}
APT_UPGRADE=${3:-$APT_UPGRADE}
APT_UPGRADE=${APT_UPGRADE:?"APT_UPGRADE is not defined"}
PKGS=${PKGS:-$4}
PKGS=${PKGS:?"Please specify list of packages"}

PKGS=$(echo $PKGS | sed s/u\'//g | tr -d "[],'")

RES=$(apt-get -c ${APT_CONF} ${APT_FLAGS} ${APT_UPGRADE} --just-print | grep "Inst")

RET=1
OUT=""

for PKG in ${PKGS}; do
    echo "${RES}" | fgrep ${PKG}  &>/dev/null && {
        (( RET = 0 ));
        OUT+="${PKG}\n"; }
done

echo "${OUT}"
exit ${RET}
