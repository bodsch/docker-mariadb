#!/bin/sh
#

set -e

. /init/output.sh
# . /init/config_backend.sh
. /init/environments.sh


set_system_user() {

  local current_user=$(grep user /etc/mysql/my.cnf | cut -d '=' -f 2 | sed 's| ||g')

  [[ "${MARIADB_SYSTEM_USER}" = "${current_user}" ]] && return

  sed -i \
    -e "s/\(user.*=\).*/\1 ${MARIADB_SYSTEM_USER}/g" \
    /etc/mysql/my.cnf
}


bootstrap_database() {

  bootstrap="${WORK_DIR}/bootstrapped"

  sed -i \
    -e "s|%WORK_DIR%|${WORK_DIR}|g" \
    /etc/mysql/my.cnf

  [[ -d ${MARIADB_DATA_DIR} ]]        || mkdir -p ${MARIADB_DATA_DIR}
  [[ -d ${MARIADB_LOG_DIR} ]]         || mkdir -p ${MARIADB_LOG_DIR}
  [[ -d ${MARIADB_TMP_DIR} ]]         || mkdir -p ${MARIADB_TMP_DIR}
  [[ -d ${MARIADB_RUN_DIR} ]]         || mkdir -p ${MARIADB_RUN_DIR}
  [[ -d ${MARIADB_INNODB_DIR} ]]      || mkdir -p ${MARIADB_INNODB_DIR}

  chown -R ${MARIADB_SYSTEM_USER}: ${WORK_DIR}

  if [[ ! -f ${bootstrap} ]]
  then

    log_info "start bootstrapping"

    [[ -f /root/.my.cnf ]] && rm /root/.my.cnf

    log_info "install initial databases"
    mysql_install_db --user=${MARIADB_SYSTEM_USER} 1> /dev/null 2> /dev/null
    [[ $? -gt 0 ]] && exit $?

    log_info "start initial instance in safe mode to set passwords"
    /usr/bin/mysqld_safe --syslog-tag=init > /dev/null 2> /dev/null &
    [[ $? -gt 0 ]] && exit $?

    set +e
    retry=30
    until [[ ${retry} -le 0 ]]
    do
      # -v              Verbose
      # -w secs         Timeout for connects and final net reads
      # -z              Zero-I/O mode (scanning)
      #
      status=$(nc -v -w1 -z 127.0.0.1 3306 2>&1)

      if [[ $? -eq 0 ]] && [[ $(echo "${status}" | grep -c open) -eq 1 ]]
      then
        break
      else
        sleep 5s
        retry=$(expr ${retry} - 1)
      fi
    done
    set -e

    log_info "create privileges for root access"
    (
      echo "USE mysql;"
      echo "UPDATE user SET password = PASSWORD('${MARIADB_ROOT_PASS}') WHERE user = 'root';"
      echo "create user 'root'@'%' IDENTIFIED BY '${MARIADB_ROOT_PASS}';"
      echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
      echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
      echo "FLUSH PRIVILEGES;"
    ) | mysql --host=localhost > /dev/null 2> /dev/null
    [[ $? -gt 0 ]] && exit $?

    sleep 2s

    log_info "kill bootstrapping instance"
    killall mysqld
    [[ $? -gt 0 ]] && exit $?

    touch ${bootstrap}
  fi

  cat << EOF > /root/.my.cnf
[client]
host     = localhost
user     = root
password = ${MARIADB_ROOT_PASS}
socket   = ${MARIADB_RUN_DIR}/mysql.sock

EOF

  sed -i \
    -e "s/\(bind-address.*=\).*/\1 0.0.0.0/g" \
    /etc/mysql/my.cnf
}


run() {

  if [[ ! -z ${MARIADB_BIN} ]]
  then

    set_system_user

    bootstrap_database

    if [[ ! -z "${CONFIG_BACKEND_SERVER}" ]] && [[ ! -z "${CONFIG_BACKEND}" ]]
    then
      save_config
      register_node
    fi

    log_info "start instance"
    /usr/bin/mysqld \
      --user=${MARIADB_SYSTEM_USER} \
      --userstat \
      --console

  else
    log_error "no MySQL binary found!"
    exit 1
  fi
}


run

# EOF
