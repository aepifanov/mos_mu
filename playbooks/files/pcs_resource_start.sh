#!/bin/bash

RESOURCE=${1:?"ERROR: Please specify resource name."}
TIMEOUT=${2:-600}

STATUS=$(pcs resource show "${RESOURCE}") ||
    { echo "WARNING: Resource ${RESOURCE} is not present!";
    exit 100;}
STATUS+=$(pcs resource show clone_"${RESOURCE}")

STATUS=$(echo "${STATUS}" | fgrep "target-role=Stopped") ||
    { echo "WARNING: Resource ${RESOURCE} is not stopped!";
    exit 1;}

pcs resource enable "${RESOURCE}" --wait="${TIMEOUT}"    ||
    { echo "ERROR: Resource ${RESOURCE} failed to start";
    exit 2;}

pcs resource cleanup "${RESOURCE}" --wait="${TIMEOUT}"

