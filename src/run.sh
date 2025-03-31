#! /bin/sh

set -e

if [ -n "${S3_S3V4:-}" ] && [ "$S3_S3V4" = "yes" ]; then
  aws configure set default.s3.signature_version s3v4
fi

COMMAND=${1:-backup}

case "$COMMAND" in
  backup)
    sh backup.sh
    ;;

  restore)
    sh restore.sh
    ;;

  schedule)
    exec go-cron "$SCHEDULE" /bin/sh backup.sh
    ;;

  custom)
    echo -e "\033[33mExecuting custom command: $@\033[0m"
    exec "$@"
    ;;

  *)
    echo -e "\033[31mError: Unknown command '$COMMAND'\033[0m"
    echo "Usage: $0 {backup|restore|schedule|custom}"
    exit 1
    ;;
esac
