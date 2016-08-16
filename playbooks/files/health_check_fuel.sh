#!/bin/bash

ENV_ID=${1:-$ENV_ID}
ENV_ID=${ENV_ID:?"ENV_ID is undefined!"}

RET=0
OUTPUT=""

check_env ()
{
    OUT=$(fuel node --env_id "${ENV_ID}" |  grep -E -v "status|---" | awk -F '|' 'BEGIN{ret=0} {input=$0;gsub(/ /,"");  if ($2 != "ready" || $9 != "True") {print input; ret=1;}} END{exit ret;}')
	if (( $? != 0 )); then
		let 'RET|=1'
		OUTPUT+="### Environment ${ENV_ID}:\n${OUT}\n"
	fi
}

check_free_disk ()
{
    OUT=$(df -h | sed 's/%//' | awk '/dev/ {if ($5 > 90) {print $0; exit 1}}')
	if [ -n  "${OUT}" ]; then
		let 'RET|=2'
		OUTPUT+="### Free disk space on Fuel:\n${OUT}\n"
	fi
}


check_env
check_free_disk

if (( ${RET} != 0 )); then
	echo -e "${OUTPUT}"
fi
exit "${RET}"
