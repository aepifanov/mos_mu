#!/bin/bash -x

OSDS=$(find -L /var/lib/ceph/osd/ -mindepth 1 -maxdepth 1 -printf '%P\n' | sed -e 's/ceph-//')
while true; do
    sleep 5
    for i in ${OSDS}; do
        status ceph-osd id=$i | grep running || break;
    done
    break
done

