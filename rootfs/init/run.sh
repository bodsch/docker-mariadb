#!/bin/bash
#

#set -eo pipefail

#set -u
#set -x

# SERVER_CNF="/etc/mysql/my.cnf"
SERVER_CNF_D="/etc/mysql"

. /init/output.sh
. /init/environments.sh

config_check() {

  # since alpine 3.9 the configuration files are located unter /etc/my.cnf.d/*.cnf

  if [ -d /etc/my.cnf.d ]
  then
    # SERVER_CNF=/etc/my.cnf
    SERVER_CNF_D=/etc/my.cnf.d
    SERVER_CONFIG_CNF="${SERVER_CNF_D}/mariadb-server.cnf"

    [ -f "${SERVER_CONFIG_CNF}" ] && rm -f "${SERVER_CONFIG_CNF}"
    [ -d /etc/mysql ] && rm -rf /etc/mysql

  fi
}

set_system_user() {

  file=$(grep -l user ${SERVER_CNF_D}/*.cnf)

  current_user=$(grep user "${file}" | cut -d '=' -f 2 | sed 's| ||g')

  if [ "${MARIADB_SYSTEM_USER}" = "${current_user}" ]
  then
    export MARIADB_SYSTEM_USER=${current_user}
    return
  fi

  export MARIADB_SYSTEM_USER

  sed -i \
    -e "s/\(user.*=\).*/\1 ${MARIADB_SYSTEM_USER}/g" \
    "${file}"
}


bootstrap_database() {

  bootstrap="${WORK_DIR}/bootstrapped"

  files=$(grep -l "%WORK_DIR%" ${SERVER_CNF_D}/*.cnf)

  for f in ${files}
  do
    sed -i \
      -e "s|%WORK_DIR%|${WORK_DIR}|g" \
      "${f}"
  done

  [ -d "${MARIADB_DATA_DIR}" ]        || mkdir -p "${MARIADB_DATA_DIR}"
  [ -d "${MARIADB_LOG_DIR}" ]         || mkdir -p "${MARIADB_LOG_DIR}"
  [ -d "${MARIADB_TMP_DIR}" ]         || mkdir -p "${MARIADB_TMP_DIR}"
  [ -d "${MARIADB_RUN_DIR}" ]         || mkdir -p "${MARIADB_RUN_DIR}"
  [ -d "${MARIADB_INNODB_DIR}" ]      || mkdir -p "${MARIADB_INNODB_DIR}"

  chown -R "${MARIADB_SYSTEM_USER}": "${WORK_DIR}"

  if [ ! -f "${bootstrap}" ]
  then

    log_info "start bootstrapping"

    [ -f /root/.my.cnf ] && rm /root/.my.cnf

    log_info "  install initial databases"
    data=$(mysql_install_db \
      --user="${MARIADB_SYSTEM_USER}")

    result=${?}

    if [ ${result} -gt 0 ]
    then
      while IFS= read -r line
      do
        log_error "${line}"
      done < <(printf '%s\n' "${data}")

      exit ${result}
    fi

    log_info "  start initial instance in safe mode to set passwords"
    data=$(/usr/bin/mysqld_safe \
      --syslog-tag=init &)

    result=${?}

    if [ ${result} -gt 0 ]
    then
      while IFS= read -r line
      do
        log_error "${line}"
      done < <(printf '%s\n' "${data}")

      exit ${result}
    fi

    set +e
    retry=30
    until [ ${retry} -le 0 ]
    do
      # -v              Verbose
      # -w secs         Timeout for connects and final net reads
      # -z              Zero-I/O mode (scanning)
      #
      status=$(nc -v -w1 -z 127.0.0.1 3306 2>&1)

      if [ $? -eq 0 ] && [ "$(echo "${status}" | grep -c open)" -eq 1 ]
      then
        break
      else
        sleep 8s
        retry=$((retry - 1))
      fi
    done
    set -e

    log_info "  create privileges for root access"
    (
      echo "USE mysql;"
      echo "UPDATE user SET password = PASSWORD('${MARIADB_ROOT_PASSWORD}') WHERE user = 'root';"
      echo "create user 'root'@'%' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';"
      echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;"
      echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;"
      echo "FLUSH PRIVILEGES;"
    ) | mysql --host=localhost > /dev/null 2> /dev/null

    [ $? -gt 0 ] && exit $?

    sleep 2s

    log_info "  kill bootstrapping instance"
    killall mysqld
    [ $? -gt 0 ] && exit $?

    touch "${bootstrap}"
  fi

  cat << EOF > /root/.my.cnf
[client]
host     = localhost
user     = root
password = ${MARIADB_ROOT_PASSWORD}
socket   = ${MARIADB_RUN_DIR}/mysql.sock

EOF

  listen=$(grep -l "bind-address" ${SERVER_CNF_D}/*.cnf)

  sed -i \
    -e "s/\(bind-address.*=\).*/\1 0.0.0.0/g" \
    "${listen}"
}


run() {

  config_check

  set_system_user

  bootstrap_database

  log_info "start instance"
  /usr/bin/mysqld \
    --user="${MARIADB_SYSTEM_USER}" \
    --userstat \
    --console
}


run

# EOF
