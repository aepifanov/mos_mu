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
	type ceph &> /dev/null ||
		return 0

	OUT=$(ceph health)
	echo -e "${OUT}" | grep HEALTH_OK &> /dev/null &&
		return 0

	RS=$(echo "${OUT}" | awk -F ';' '{
		exc[0] = "too many PGs per OSD"
		for (i=1; i<=NF; i++) {
			skip = 0
			for (e in exc) {
				if (match ($i, exc[e]) != 0)
					skip = 1
			}
			if ( skip == 0 )
				print $i;
		}
	}')
	[ -z "${RS}" ] &&
		return 0

	(( RET |= 8 ))
	OUTPUT+="### ceph:\n${OUT}\n"
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
