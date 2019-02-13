#!/bin/sh

. /init/environments.sh

bootstrap="${WORK_DIR}/bootstrapped"

set -eo pipefail
#
# if [ "$MYSQL_RANDOM_ROOT_PASSWORD" ] && [ -z "$MYSQL_USER" ] && [ -z "$MYSQL_PASSWORD" ]; then
#   # there's no way we can guess what the random MySQL password was
#   echo >&2 'healthcheck error: cannot determine random root password (and MYSQL_USER and MYSQL_PASSWORD were not set)'
#   exit 0
# fi

while true
do
  if [ ! -f ${bootstrap} ]
  then
    sleep 5s
  else
    break
  fi
done

if select="$(echo 'SELECT 1' | mysql --defaults-file="/root/.my.cnf" --silent)" && [ "${select}" = '1' ]
then
  exit 0
fi

exit 1
