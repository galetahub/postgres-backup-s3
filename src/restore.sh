#! /bin/sh

set -u
set -o pipefail

s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}"

if [ -z "$PASSPHRASE" ]; then
  file_type=".dump"
else
  file_type=".dump.gpg"
fi

if [ -z "$S3_PREFIX" ]; then
  export DESTINATION="s3://${S3_BUCKET}"
else
  export DESTINATION="s3://${S3_BUCKET}/${S3_PREFIX}"
fi

if [ $# -eq 1 ]; then
  timestamp="$1"
  key_suffix="${POSTGRES_DATABASE}_${timestamp}"
else
  echo "\033[33mFinding latest backup...\033[0m"
  key_suffix=$(
    aws $aws_args s3 ls "${DESTINATION}/${POSTGRES_DATABASE}" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
fi

s3_uri_base="${DESTINATION}/${key_suffix}.${file_type}"

echo "\033[33mFetching backup from S3: ${s3_uri_base}\033[0m"
aws $aws_args s3 cp "${s3_uri_base}" "db${file_type}"

if [ -n "$PASSPHRASE" ]; then
  echo "\033[33mDecrypting backup...\033[0m"
  gpg --decrypt --batch --passphrase "$PASSPHRASE" db.dump.gpg > db.dump
  rm db.dump.gpg
fi

echo "\033[33mRestoring from backup...\033[0m"
pg_restore -h "$POSTGRES_HOST" \
           -p "$POSTGRES_PORT" \
           -U "$POSTGRES_USER" \
           -d "$POSTGRES_DATABASE" \
           $PGRESTORE_EXTRA_OPTS db.dump

# Clean up
rm db.dump

echo -e "\033[32mRestore complete 🚀.\033[0m"
