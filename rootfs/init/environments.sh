

HOSTNAME=$(hostname -f)

WORK_DIR=/srv/mysql

MYSQL_DATA_DIR=${WORK_DIR}/data
MYSQL_LOG_DIR=${WORK_DIR}/log
MYSQL_TMP_DIR=${WORK_DIR}/tmp
MYSQL_RUN_DIR=${WORK_DIR}/run
MYSQL_INNODB_DIR=${WORK_DIR}/innodb

MYSQL_SYSTEM_USER=${MYSQL_SYSTEM_USER:-$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-$(pwgen -s 25 1)}

MYSQL_OPTS="--batch --skip-column-names "
MYSQL_BIN=$(which mysql)

if [[ ! -z "${CONFIG_BACKEND_SERVER}" ]] && [[ ! -z "${CONFIG_BACKEND}" ]]
then
  wait_for_config_backend

  PASSWORD=$(get_var "root_password")
fi

echo ""

log_info "generated password          :  '${MYSQL_ROOT_PASS}'"
log_info "restored from config backend: '${PASSWORD}'"

[[ -z "${PASSWORD}" ]] || MYSQL_ROOT_PASS=${PASSWORD}

#exit 0

log_info "set MYSQL_ROOT_PASS to '${MYSQL_ROOT_PASS}'"
