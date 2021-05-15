#!/bin/bash

# terminate script as soon as any command fails
set -e

if [[ -z "$APP" ]]; then
  echo "Missing APP variable which must be set to the name of your app where the db is located"
  exit 1
fi

if [[ -z "$DATABASE" ]]; then
  echo "Missing DATABASE variable which must be set to the name of the DATABASE you would like to backup"
  exit 1
fi

if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable which must be set the directory in s3 where you would like to store your database backups"
  exit 1
fi

# install aws-cli
#  - this will already exist if we're running the script manually from a dyno more than once

BACKUP_FILE_NAME="$(date +"%Y-%m-%d-%H-%M").dump"

curl -o $BACKUP_FILE_NAME `heroku pg:backups:url --app $APP`
gzip $BACKUP_FILE_NAME
/tmp/aws/bin/aws s3 cp $BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$S3_DIRECTORY_PATH/$BACKUP_FILE_NAME.gz --sse
echo "backup $BACKUP_FILE_NAME complete"

if [[ -n "$HEARTBEAT_URL" ]]; then
  echo "Sending a request to the specified HEARTBEAT_URL that the backup was created"
  curl $HEARTBEAT_URL
  echo "heartbeat complete"
fi
