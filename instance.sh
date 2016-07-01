#!/bin/bash
set -o allexport

CMD=$1
NAME=$2
FORK=$3
BRANCH=$4
#DROP_DB=$5
DOMAIN=spistresci.pl
BASE_DIR=/home/dkr/SpisTresci/
INSTANCE_DIR=${BASE_DIR}${NAME}

remove_instance(){
  if [ -d "$INSTANCE_DIR" ]; then
    cd $INSTANCE_DIR
    set -o allexport
    source ./.env

    docker-compose stop
    docker-compose rm -v -f
    cd ../

    rm -rf $INSTANCE_DIR
  fi
}

create_instance(){
  git clone -b $BRANCH https://github.com/$FORK/SpisTresci.git $INSTANCE_DIR
  cd $INSTANCE_DIR
  cp $BASE_DIR/test.env ./.env
  sed -i "1s/^/HOST_ADDRESS=$NAME.$DOMAIN\n/"  $INSTANCE_DIR/.env

  set -o allexport
  source ./.env

  docker-compose build --no-cache
  docker-compose up -d postgres
  sleep 10
  docker-compose up -d
  docker-compose run django python manage.py migrate
}

if [ $CMD = "remove" ]; then
  remove_instance
fi

if [ $CMD = "create" ]; then
  remove_instance
  create_instance
fi


#BACKUP_OUTPUT=`docker-compose run postgres backup | tail -n 1 | awk '{ print $NF }'`
#trim whitespaces - http://stackoverflow.com/questions/369758/
#BACKUP_FILE="$(echo -e "${BACKUP_OUTPUT}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
#docker cp alphaspistrescipl_postgres_1:/backups/$BACKUP_FILE /tmp/

#docker cp /tmp/$BACKUP_FILE stagingspistrescipl_postgres_1:/backups/
#docker-compose run postgres restore $BACKUP_FILE
