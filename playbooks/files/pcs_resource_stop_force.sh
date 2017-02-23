#!/bin/bash

RESOURCE=${1:?"ERROR: Please specify resource name."}


OUT=$(pcs resource show "${RESOURCE}") || {
    echo "WARNING: Resource ${RESOURCE} is not present!";
    exit 100;}
DETAILES=${OUT}
OUT+=$(pcs resource show clone_"${RESOURCE}")

echo "${OUT}" | fgrep "target-role=Stopped" || {
    echo "WARNING: Resource ${RESOURCE} is not stopped!"
    exit 1;}

PROVIDER=$(echo "${DETAILES}" | awk '/Resource/ {for(i=1;i<=NF;i++) {if(match($i,"provider")) {gsub(".*\=","",$i);gsub("[\(\)]","",$i);print $i}}}')
TYPE=$(    echo "${DETAILES}" | awk '/Resource/ {for(i=1;i<=NF;i++) {if(match($i,"type"))     {gsub(".*\=","",$i);gsub("[\(\)]","",$i);print $i}}}')

export OCF_ROOT=/usr/lib/ocf
${OCF_ROOT}/resource.d/${PROVIDER}/${TYPE} stop
