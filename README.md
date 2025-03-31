# Introduction

Stream DB dump direcly to S3 bucket

This project provides Docker images to periodically back up a PostgreSQL database to AWS S3, and to restore from the backup as needed.

# Usage

## Backup

### Docker compose schedule backup

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password

  backup:
    image: eeshugerman/postgres-backup-s3:16
    command: schedule
    environment:
      SCHEDULE: '@weekly'     # optional
      BACKUP_KEEP_DAYS: 7     # optional
      PASSPHRASE: passphrase  # optional
      S3_REGION: region
      S3_ACCESS_KEY_ID: key
      S3_SECRET_ACCESS_KEY: secret
      S3_BUCKET: my-bucket
      S3_PREFIX: backup
      POSTGRES_HOST: postgres
      POSTGRES_DATABASE: dbname
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
```

- Images are tagged by the major PostgreSQL version supported: `12`, `13`, `14`, `15` or `16`.
- The `SCHEDULE` variable determines backup frequency. See go-cron schedules documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup immediately and then exit.
- If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
- Run `docker exec <container name> sh backup.sh` to trigger a backup ad-hoc.
- If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from S3.
- Set `S3_ENDPOINT` if you're using a non-AWS S3-compatible storage provider.

### From CLI

```sh
docker run \
  -e S3_REGION=us-east-1 \
  -e S3_BUCKET=backups \
  -e S3_ACCESS_KEY_ID=key \
  -e S3_SECRET_ACCESS_KEY=secret \
  -e POSTGRES_HOST=rds.amazonaws.com \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DATABASE=database \
  -e PGDUMP_EXTRA_OPTS="--no-owner --no-privileges --no-acl" \
  galetahub/postgres-backup-s3:13
```

## Restore

> [!CAUTION]
> DATA LOSS! All database objects will be dropped and re-created (see PGRESTORE_EXTRA_OPTS).

### Restore from latest backup

```sh
docker run \
  -e S3_REGION=us-east-1 \
  -e S3_BUCKET=backups \
  -e S3_ACCESS_KEY_ID=key \
  -e S3_SECRET_ACCESS_KEY=secret \
  -e POSTGRES_HOST=rds.amazonaws.com \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DATABASE=database \
  -e PGRESTORE_EXTRA_OPTS="--clean --if-exists" \
  galetahub/postgres-backup-s3:13 restore
```

> [!NOTE]
> If your bucket has more than a 1000 files, the latest may not be restored -- only one S3 `ls` command is used

### Restore from specific backup

```sh
docker run \
  -e S3_REGION=us-east-1 \
  -e S3_BUCKET=backups \
  -e S3_ACCESS_KEY_ID=key \
  -e S3_SECRET_ACCESS_KEY=secret \
  -e POSTGRES_HOST=rds.amazonaws.com \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DATABASE=database \
  -e PGRESTORE_EXTRA_OPTS="--clean --if-exists" \
  galetahub/postgres-backup-s3:13 restore <timestamp>
```

# Development

## Build the image locally
`ALPINE_VERSION` determines Postgres version compatibility. See [`build-and-push-images.yml`](.github/workflows/build-and-push-images.yml) for the latest mapping.
```sh
DOCKER_BUILDKIT=1 docker build --build-arg ALPINE_VERSION=3.14 .

docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.18 --build-arg PG_VERSION=12 -t postgres-backup-s3:12 .
docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.19 --build-arg PG_VERSION=13 -t postgres-backup-s3:13 .
docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.19 --build-arg PG_VERSION=14 -t postgres-backup-s3:14 .
docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.19 --build-arg PG_VERSION=15 -t postgres-backup-s3:15 .
docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.20 --build-arg PG_VERSION=16 -t postgres-backup-s3:16 .
docker build --platform=linux/x86_64 --build-arg ALPINE_VERSION=3.21 --build-arg PG_VERSION=17 -t postgres-backup-s3:17 .
```
## Run a simple test environment with Docker Compose
```sh
cp template.env .env
# fill out your secrets/params in .env
docker compose up -d
```

# Acknowledgements

This project is a fork and re-structuring of @schickling's [postgres-backup-s3](https://github.com/schickling/dockerfiles/tree/master/postgres-backup-s3) and [postgres-restore-s3](https://github.com/schickling/dockerfiles/tree/master/postgres-restore-s3).

## Fork goals

These changes would have been difficult or impossible merge into @schickling's repo or similarly-structured forks.
  - dedicated repository
  - automated builds
  - support multiple PostgreSQL versions
  - backup and restore with one image

## Other changes and features
  - some environment variables renamed or removed
  - uses `pg_dump`'s `custom` format (see [docs](https://www.postgresql.org/docs/10/app-pgdump.html))
  - drop and re-create all database objects on restore
  - backup blobs and all schemas by default
  - no Python 2 dependencies
  - filter backups on S3 by database name
  - support encrypted (password-protected) backups
  - support for restoring from a specific backup by timestamp
  - support for auto-removal of old backups
