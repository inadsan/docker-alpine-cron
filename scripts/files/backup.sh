#!/bin/bash

. /files/functions

if [[ -n "$DB_DUMP_DEBUG" ]]; then
  set -x
fi

# get all variables from environment variables or files (e.g. VARIABLE_NAME_FILE)
# (setting defaults happens here, too)
file_env "DB_NAMES"
file_env "DB_NAMES_EXCLUDE"

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

file_env "COMPRESSION" "gzip"

if [[ -n "$DB_DUMP_DEBUG" ]]; then
  set -x
fi

#
# set compress and decompress commands
COMPRESS=
case $COMPRESSION in
  gzip)
    COMPRESS="gzip"
    EXTENSION="tar.gz"
    ;;
  bzip2)
    COMPRESS="bzip2"
    EXTENSION="tar.bz2"
    ;;
  *)
    echo "Unknown compression requested: $COMPRESSION" >&2
    exit 1
esac

# temporary dump dir
TMPDIR="${TMP_PATH}/backups"

# this is global, so has to be set outside
declare -A uri

  # wait for the next time to start a backup
  # for debugging
  echo Starting at $(date)

    # make sure the directory exists
    mkdir -p $TMPDIR
    do_dump
    [ $? -ne 0 ] && exit_code=1
    # we can have multiple targets
    for target in ${DB_DUMP_TARGET}; do
      backup_target ${target}
      [ $? -ne 0 ] && exit_code=1
    done
    # remove lingering file
    /bin/rm ${TMPDIR}/${SOURCE}

    exit $exit_code
