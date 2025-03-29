#! /bin/sh

set -e
set -o pipefail

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}/${POSTGRES_DATABASE}_${timestamp}.dump"

if [ -z "$PGDUMP_EXTRA_OPTS" ]; then
  export PGDUMP_EXTRA_OPTS=""
fi

echo -e "\033[33mCreating backup of $POSTGRES_DATABASE database...\033[0m"
echo -e "\033[33mDestination: $s3_uri_base\033[0m"

pg_dump -h "$POSTGRES_HOST" \
        -p "$POSTGRES_PORT" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DATABASE" \
        $PGDUMP_EXTRA_OPTS | aws s3 cp - "$s3_uri_base"

echo -e "\033[32mBackup complete.\033[0m"
