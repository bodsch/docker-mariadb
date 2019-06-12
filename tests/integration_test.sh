#!/bin/bash

prepare() {

  pushd $PWD > /dev/null

  cd $(dirname $(readlink -f "$0"))

  if [[ -f ../.env ]]
  then
    . ../.env

    if [[ -z "${MARIADB_SYSTEM_USER}" ]] || [[ -z "${MARIADB_ROOT_PASSWORD}" ]]
    then
      echo "run 'make compose-file' first"
      exit 1
    fi
  else
    echo "run 'make compose-file' first"
    exit 1
  fi

  MARIADB_PORT=33060

  cat << EOF > /tmp/.root-my.cnf
[client]
host     = 127.0.0.1
user     = ${MARIADB_SYSTEM_USER}
password = ${MARIADB_ROOT_PASSWORD}
port     = ${MARIADB_PORT}
# socket   = ${MARIADB_RUN_DIR}/mysql.sock

EOF

  TEST_SCHEMA="QA_TEST"
  DBA_USER="QA"
  DBA_PASSWORD=$(< /dev/urandom tr -dc A-Z-a-z-0-9 | fold -w 32 | head -n 1; echo)
  DBA_OPTS="
    --defaults-file=/tmp/.root-my.cnf
    --batch --skip-column-names"

  popd > /dev/null

}

# wait for the database
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
      RETRY=$((RETRY - 1))
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
    RETRY=$((RETRY - 1))
  done

  echo ""
}

check_schema() {

  echo ""
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
  echo ""
}


inspect() {

  echo ""
  echo "inspect needed containers"
  for d in $(docker ps | tail -n +2 | awk  '{print($1)}')
  do
    # docker inspect --format "{{lower .Name}}" ${d}
    c=$(docker inspect --format '{{with .State}} {{$.Name}} has pid {{.Pid}} {{end}}' ${d})
    s=$(docker inspect --format '{{json .State.Health }}' ${d} | jq --raw-output .Status)

    printf "%-40s - %s\n"  "${c}" "${s}"
  done
  echo ""
}


if [[ $(docker ps | tail -n +2 | grep -c mariadb) -eq 1 ]]
then
  inspect

  prepare

  wait_for_database
  check_schema

  exit 0
else
  echo "please run "
  echo " make compose-file"
  echo " docker-compose up --build -d"
  echo "before"

  exit 1
fi

exit 0
