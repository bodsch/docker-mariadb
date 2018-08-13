#!/bin/sh

set -x

set -eo pipefail
#
# if [ "$MYSQL_RANDOM_ROOT_PASSWORD" ] && [ -z "$MYSQL_USER" ] && [ -z "$MYSQL_PASSWORD" ]; then
#   # there's no way we can guess what the random MySQL password was
#   echo >&2 'healthcheck error: cannot determine random root password (and MYSQL_USER and MYSQL_PASSWORD were not set)'
#   exit 0
# fi

host="$(hostname -i || echo '127.0.0.1')"

if select="$(echo 'SELECT 1' | mysql --defaults-file="/root/.my.cnf" --host="${host}" --silent)" && [[ "${select}" = '1' ]]
then
  exit 0
fi

exit 1
