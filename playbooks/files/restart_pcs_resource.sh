#!/bin/bash

RESOURCE=${1:?"ERROR: Please specify resource name."}
TIMEOUT=${2:-600}

STATUS=$(pcs resource show "${RESOURCE}") ||
    { echo "WARNING: Resource ${RESOURCE} is not present!";
    exit 100;}

pcs resource cleanup "${RESOURCE}" --wait="${TIMEOUT}"

STATUS=$(echo "${STATUS}" | fgrep "target-role=Stopped") &&
    { echo "WARNING: Resource ${RESOURCE} is stopped!";
    exit 1;}

sleep 5

pcs resource debug-stop "${RESOURCE}" ||
    { echo "ERROR: Resource ${RESOURCE} failed to stop";
    exit 2;}
