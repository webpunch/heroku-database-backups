#!/bin/bash

# terminate script as soon as any command fails
set -e

if [[ -z "$APP" ]]; then
  echo "Missing APP variable which must be set to the name of your app where the db is located"
  exit 1
fi

if [[ -z "$HEROKU_BACKUP_NAME" ]]; then
  echo "Missing HEROKU_BACKUP_NAME variable which must be set to the backup name on heroku (for example b2725)"
  exit 1
fi

if [[ -z "$S3_BUCKET_PATH" ]]; then
  echo "Missing S3_BUCKET_PATH variable which must be set the directory in s3 where you would like to store your database backups"
  exit 1
fi

#install aws-cli
curl https://s3.amazonaws.com/aws-cli/awscli-bundle.zip -o awscli-bundle.zip
unzip awscli-bundle.zip
chmod +x ./awscli-bundle/install
./awscli-bundle/install -i /tmp/aws

BACKUP_FILE_NAME="$(date +"%Y-%m-%d")-heroku-$HEROKU_BACKUP_NAME.dump"

curl -o $BACKUP_FILE_NAME `heroku pg:backups:url $HEROKU_BACKUP_NAME --app $APP`
gzip $BACKUP_FILE_NAME
/tmp/aws/bin/aws s3 cp $BACKUP_FILE_NAME.gz s3://$S3_BUCKET_PATH/$S3_DIRECTORY_PATH/$BACKUP_FILE_NAME.gz --sse
echo "backup $BACKUP_FILE_NAME complete"
