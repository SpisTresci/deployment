#!/bin/bash

FORK=$1
BRANCH=$2

cd /home/dkr/SpisTresci/alpha
set -o allexport
source ./.env

BACKUP_OUTPUT=`docker-compose run postgres backup | tail -n 1 | awk '{ print $NF }'`

#trim whitespaces - http://stackoverflow.com/questions/369758/
BACKUP_FILE="$(echo -e "${BACKUP_OUTPUT}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

docker cp alphaspistrescipl_postgres_1:/backups/$BACKUP_FILE /tmp/


cd /home/dkr/SpisTresci/staging
source ./.env

docker-compose stop
docker-compose rm -v -f

git fetch $FORK
git checkout $FORK/$BRANCH -f
git checkout -b $BRANCH-`date +%s`
git branch | grep -v "*" | xargs git branch -D

source ./.env
docker-compose build --no-cache
docker-compose up -d postgres
docker cp /tmp/$BACKUP_FILE stagingspistrescipl_postgres_1:/backups/
docker-compose run postgres restore $BACKUP_FILE

docker-compose up -d
docker-compose run django python manage.py migrate

