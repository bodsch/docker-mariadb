#!/bin/bash

pushd $PWD

cd $(dirname $(readlink -f "$0"))

if [[ -f ../.env ]]
then
  . ../.env
else
  echo "run 'make compose-file' first"
  exit 1
fi

if [[ -z "${MARIADB_SYSTEM_USER}" ]] || [[ -z "${MARIADB_ROOT_PASSWORD}" ]]
then
  echo "run 'make compose-file' first"
  exit 1
fi

MARIADB_PORT=33060

TEST_SCHEMA="QA_TEST"
DBA_USER="QA"
DBA_PASSWORD="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
DBA_OPTS="--host=127.0.0.1 --user=${MARIADB_SYSTEM_USER} --password=${MARIADB_ROOT_PASSWORD} --port=${MARIADB_PORT} --batch --skip-column-names"

popd

# wait for the Icinga2 Master
#
wait_for_database() {

  echo "wait for the database"

  # now wait for ssh port
  RETRY=40
  until [[ ${RETRY} -le 0 ]]
  do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/127.0.0.1/${MARIADB_PORT}" 2> /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 3s
      RETRY=$(expr ${RETRY} - 1)
    fi
  done

  if [[ $RETRY -le 0 ]]
  then
    echo "could not connect to the database instance"
    exit 1
  fi

  RETRY=10

  # must start initdb and do other jobs well
  #
  echo -n "wait for the database for her initdb and all other jobs "

  until [[ ${RETRY} -le 0 ]]
  do
    mysql ${DBA_OPTS} --execute="select 1 from mysql.user limit 1" > /dev/null 2> /dev/null

    [[ $? -eq 0 ]] && break

    echo -n " ."
    sleep 3s
    RETRY=$(expr ${RETRY} - 1)
  done

  echo ""
}

check_schema() {

  # check if database already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${TEST_SCHEMA}\" limit 1;"

  status=$(mysql ${DBA_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    echo "create database schema '${TEST_SCHEMA}'"

    (
      echo "CREATE DATABASE IF NOT EXISTS ${TEST_SCHEMA};"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON ${TEST_SCHEMA}.* TO '${DBA_USER}'@'%' IDENTIFIED BY '${DBA_PASSWORD}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${DBA_OPTS}

    if [[ $? -eq 1 ]]
    then
      echo "can't create schema '${TEST_SCHEMA}'"
      exit 1
    fi

    echo "successful"
  fi
}


inspect() {

  echo "inspect needed containers"
  for d in database
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d}
  done
}

inspect
wait_for_database
check_schema

exit 0

