#!/bin/bash

. /mysql/functions

if [[ -n "$DB_DUMP_DEBUG" ]]; then
  set -x
fi

# get all variables from environment variables or files (e.g. VARIABLE_NAME_FILE)
# (setting defaults happens here, too)
file_env "DB_SERVER"
file_env "DB_PORT"
file_env "DB_USER"
file_env "DB_PASS"
file_env "DB_NAMES"
file_env "DB_NAMES_EXCLUDE"

file_env "DB_DUMP_DEBUG"
file_env "DB_DUMP_TARGET" "/backup"
file_env "DB_DUMP_BY_SCHEMA"
file_env "DB_DUMP_KEEP_PERMISSIONS" "true"
file_env "DB_DUMP_OLDDAYS_REMOVE"

file_env "AWS_ENDPOINT_URL"
file_env "AWS_ENDPOINT_OPT"
file_env "AWS_CLI_OPTS"
file_env "AWS_CLI_S3_CP_OPTS"
file_env "AWS_ACCESS_KEY_ID"
file_env "AWS_SECRET_ACCESS_KEY"
file_env "AWS_DEFAULT_REGION"

file_env "SMB_USER"
file_env "SMB_PASS"

file_env "TMP_PATH" "/tmp"

file_env "COMPRESSION" "bzip2"

if [[ -n "$DB_DUMP_DEBUG" ]]; then
  set -x
fi

# ensure it is defined
MYSQLDUMP_OPTS=${MYSQLDUMP_OPTS:-}

# login credentials
if [ -n "${DB_USER}" ]; then
  DBUSER="-u${DB_USER}"
else
  DBUSER=
fi
if [ -n "${DB_PASS}" ]; then
  DBPASS="-p${DB_PASS}"
else
  DBPASS=
fi

# database server
if [ -z "${DB_SERVER}" ]; then
  echo "DB_SERVER variable is required. Exiting."
  exit 1
fi
# database port
if [ -z "${DB_PORT}" ]; then
  echo "DB_PORT not provided, defaulting to 3306"
  DB_PORT=3306
fi

#
# set compress and decompress commands
COMPRESS=
case $COMPRESSION in
  gzip)
    COMPRESS="gzip"
    EXTENSION=".gz"
    ;;
  bzip2)
    COMPRESS="bzip2"
    EXTENSION=".bz2"
    ;;
  *)
    echo "Unknown compression requested: $COMPRESSION" >&2
    exit 1
esac


# temporary dump dir
TMPDIR="${TMP_PATH}/backups"
SOURCE_PREFIX="db_backup"

# this is global, so has to be set outside
declare -A uri

echo Starting at $(date)

# enter the loop
exit_code=0
# make sure the directory exists
mkdir -p $TMPDIR
do_dump
[ $? -ne 0 ] && exit_code=1
# we can have multiple targets
for target in ${DB_DUMP_TARGET}; do
  backup_target ${target}
  [ $? -ne 0 ] && exit_code=1
  delete_target ${target}
  [ $? -ne 0 ] && exit_code=1
done

# remove lingering file
/bin/rm ${TMPDIR}/${SOURCE}

exit $exit_code
