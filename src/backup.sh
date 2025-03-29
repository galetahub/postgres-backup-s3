#! /bin/sh

set -e

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}/${POSTGRES_DATABASE}_${timestamp}.dump"

source ./env.sh

echo "Creating backup of $POSTGRES_DATABASE database..."
pg_dump -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DATABASE \
        $PGDUMP_EXTRA_OPTS | aws s3 cp - $s3_uri_base

echo "Backup complete."
