#!/bin/bash

APT_CONF=${1:-$APT_CONF}
APT_CONF=${APT_CONF:-"/root/mos_mu/apt/apt.conf"}
APT_UPGRADE=${2:-$APT_UPGRADE}
APT_UPGRADE=${APT_UPGRADE:?"APT_UPGRADE is not defined"}
PKGS=${PKGS:-$3}
PKGS=${PKGS:?"Please specify list of packages"}


PKGS=$(echo $PKGS | sed s/u\'//g | tr -d "[],'")

RES=$(apt-get -c "${APT_CONF}" "${APT_UPGRADE}" --just-print | grep "Inst")

RET=1
OUT=""

for PKG in ${PKGS}; do
    echo "${RES}" | fgrep ${PKG}  &>/dev/null && {
        (( RET = 0 ));
        OUT+="${PKG}\n"; }
done

echo "${OUT}"
exit ${RET}
