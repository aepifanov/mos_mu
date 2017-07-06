#!/bin/bash

BACKUP_DIR=${BACKUP_DIR:$1}
BACKUP_DIR=${BACKUP_DIR:?"ERROR: Please specify backup directory."}

BACKUP_NAME="backup_mysql"
BACKUP_PATH+="${BACKUP_NAME}"

rm -rf "${BACKUP_PATH}"

innobackupex --host localhost --no-timestamp "${BACKUP_PATH}" &> /dev/null ||
    exit 1

innobackupex --host localhost --apply-log "${BACKUP_PATH}" &> /dev/null ||
    exit 2

BACKUP_FILE="${BACKUP_NAME}_$(date +%m.%d.%y__%H-%M-%S).tgz"
tar -czf "${BACKUP_DIR}/${BACKUP_FILE}" "${BACKUP_PATH}" &> /dev/null ||
    exit 3

rm -rf "${BACKUP_PATH}"

echo -e "${BACKUP_FILE}"
