#! /bin/sh

set -e
set -o pipefail

if [ -z "$PGDUMP_EXTRA_OPTS" ]; then
  export PGDUMP_EXTRA_OPTS=""
fi

if [ -z "$S3_PREFIX" ]; then
  export DESTINATION="s3://${S3_BUCKET}"
else
  export DESTINATION="s3://${S3_BUCKET}/${S3_PREFIX}"
fi

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
s3_uri_base="${DESTINATION}/${POSTGRES_DATABASE}_${timestamp}.dump"

echo -e "\033[33mCreating backup of $POSTGRES_DATABASE database...\033[0m"
echo -e "\033[33mDestination: $s3_uri_base\033[0m"

pg_dump -h "$POSTGRES_HOST" \
        -p "$POSTGRES_PORT" \
        -U "$POSTGRES_USER" \
        -d "$POSTGRES_DATABASE" \
        $PGDUMP_EXTRA_OPTS | aws s3 cp - "$s3_uri_base"

echo -e "\033[32mBackup complete.\033[0m"
