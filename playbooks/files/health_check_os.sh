#!/bin/bash

RET=0
OUTPUT=""

check_nova ()
{
	OUT=$(nova service-list)
	if (( $? != 0 )); then
		(( RET |= 1 ))
	fi
	OUT=$(echo -e "${OUT}" | grep -i down)
	if (( $? == 0 )); then
		(( RET |= 1 ))
		OUTPUT+="### nova:\n${OUT}\n"
	fi
}

check_neutron ()
{
	OUT=$(neutron agent-list)
	if (( $? != 0 )); then
		(( RET |= 2 ))
	fi
	OUT=$(echo -e "${OUT}" | grep -i xxx)
	if (( $? == 0 )); then
		(( RET |= 2 ))
		OUTPUT+="### neutron:\n${OUT}\n"
	fi
}

check_cinder ()
{
	OUT=$(cinder service-list)
	if (( $? != 0 )); then
		(( RET |= 4 ))
	fi
	OUT=$(echo -e "${OUT}" | grep -i down)
	if (( $? == 0 )); then
		(( RET |= 4 ))
		OUTPUT+="### cinder:\n${OUT}\n"
	fi
}

check_ceph ()
{
    type ceph || return 0

    OUT=$(ceph -s)
    echo -e "${OUT}" | grep HEALTH_OK
	if (( $? != 0 )); then
		(( RET |= 8 ))
		OUTPUT+="### ceph:\n${OUT}\n"
	fi
}

source /root/openrc

check_nova
check_neutron
check_cinder
check_ceph

if (( RET != 0 )); then
	echo -e "${OUTPUT}"
fi
exit "${RET}"
