

HOSTNAME=$(hostname -f)

WORK_DIR=/srv/mysql

MARIADB_DATA_DIR=${WORK_DIR}/data
MARIADB_LOG_DIR=${WORK_DIR}/log
MARIADB_TMP_DIR=${WORK_DIR}/tmp
MARIADB_RUN_DIR=${WORK_DIR}/run
MARIADB_INNODB_DIR=${WORK_DIR}/innodb

MARIADB_SYSTEM_USER=${MARIADB_SYSTEM_USER:-$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')}

if [[ -z ${IDO_PASSWORD} ]]
then
#   MARIADB_ROOT_PASS=${MARIADB_ROOT_PASS:-$(pwgen -s 25 1)}
  MARIADB_ROOT_PASS=$(pwgen -s 15 1)

  log_warn "NO ROOT PASSWORD HAS BEEN SET!"
  log_warn "DATABASE CONNECTIONS ARE NOT RESTART SECURE!"
  log_warn "DYNAMICALLY GENERATED PASSWORD: '${MARIADB_ROOT_PASS}' (ONLY VALID FOR THIS SESSION)"
fi

MARIADB_OPTS="--batch --skip-column-names "
MARIADB_BIN=$(which mysql)

#if [[ ! -z "${CONFIG_BACKEND_SERVER}" ]] && [[ ! -z "${CONFIG_BACKEND}" ]]
#then
#  wait_for_config_backend
#
#  PASSWORD=$(get_var "root_password")
#fi
#
#echo ""

# log_info "generated password          :  '${MARIADB_ROOT_PASS}'"
# log_info "restored from config backend: '${PASSWORD}'"
# [[ -z "${PASSWORD}" ]] || MARIADB_ROOT_PASS=${PASSWORD}

#exit 0

# log_info "set MARIADB_ROOT_PASS to '${MARIADB_ROOT_PASS}'"
