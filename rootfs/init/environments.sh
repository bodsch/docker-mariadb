

HOSTNAME=$(hostname -f)

WORK_DIR=/srv/mysql

MARIADB_DATA_DIR=${WORK_DIR}/data
MARIADB_LOG_DIR=${WORK_DIR}/log
MARIADB_TMP_DIR=${WORK_DIR}/tmp
MARIADB_RUN_DIR=${WORK_DIR}/run
MARIADB_INNODB_DIR=${WORK_DIR}/innodb

MARIADB_SYSTEM_USER=${MARIADB_SYSTEM_USER:-$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')}

if [[ -z ${MARIADB_ROOT_PASSWORD} ]]
then
  MARIADB_ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

  log_warn "NO ROOT PASSWORD HAS BEEN SET!"
  log_warn "DATABASE CONNECTIONS ARE NOT RESTART SECURE!"
  log_warn "DYNAMICALLY GENERATED PASSWORD: '${MARIADB_ROOT_PASSWORD}' (ONLY VALID FOR THIS SESSION)"
fi

MARIADB_OPTS="--batch --skip-column-names "
MARIADB_BIN=$(which mysql)
