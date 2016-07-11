#!/bin/bash

RESOURCE=${1:?"ERROR: Please specify resource name."}
TIMEOUT=${2:-600}


STATUS=$(pcs resource show ${RESOURCE}) || { echo "WARNING: Resource ${RESOURCE} is not present!"; exit 1;}
pcs resource cleanup ${RESOURCE} --wait=${TIMEOUT}
STATUS=$(echo "${STATUS}" | fgrep "target-role=Stopped") && { echo "WARNING: Resource ${RESOURCE} is stopped!"; exit 1;}

pcs resource disable ${RESOURCE} --wait=${TIMEOUT}     && \
    sleep 10                                           && \
    pcs resource enable  ${RESOURCE} --wait=${TIMEOUT} || \
    { echo "ERROR: Resource ${RESOURCE} failed to start"; exit 1;}
