#!/bin/sh

wait_for_config_backend() {

  [[ -z "${CONFIG_BACKEND_SERVER}" ]] || [[ -z "${CONFIG_BACKEND}"  ]] && return

  RETRY=50
  local http_response_code=0

  until [[ 200 -ne $http_response_code ]] && [[ ${RETRY} -le 0 ]]
  do
    http_response_code=$(curl \
      -w %{response_code} \
      --silent \
      --output /dev/null \
      ${CONFIG_BACKEND_SERVER}:8500/v1/health/service/consul)

    [[ 200 -eq $http_response_code ]] && break

    sleep 5s

    RETRY=$(expr ${RETRY} - 1)
  done

  if [[ ${RETRY} -le 0 ]]
  then
    log_error "could not connect to the consul master instance '${CONFIG_BACKEND_SERVER}'"
    CONSUL=
    CONFIG_BACKEND=
  fi
}

register_node()  {

  [[ -z "${CONFIG_BACKEND_SERVER}" ]] || [[ -z "${CONFIG_BACKEND}"  ]] && return

  local address=$(hostname -i)

  data=$(curl \
    --silent \
    --request PUT \
    ${CONFIG_BACKEND_SERVER}:8500/v1/agent/service/register \
    --data '{
      "ID": "'${HOSTNAME}'",
      "Name": "'${HOSTNAME}'",
      "Port": 3306,
      "Address": "'${address}'",
      "tags": ["database"]
    }')

  echo "${data}"
}

set_var() {

  [[ -z "${CONFIG_BACKEND_SERVER}" ]] || [[ -z "${CONFIG_BACKEND}"  ]] && return

  local consul_key=${1}
  local consul_var=${2}

  data=$(curl \
    --request PUT \
    --silent \
    ${CONFIG_BACKEND_SERVER}:8500/v1/kv/${HOSTNAME}/${consul_key} \
    --data ${consul_var})

#  curl \
#    --silent \
#    ${CONFIG_BACKEND_SERVER}:8500/v1/kv/${consul_key}
}

get_var() {

  [[ -z "${CONFIG_BACKEND_SERVER}" ]] || [[ -z "${CONFIG_BACKEND}"  ]] && return

  local consul_key=${1}

  data=$(curl \
    --silent \
    ${CONFIG_BACKEND_SERVER}:8500/v1/kv/${HOSTNAME}/${consul_key})

  if [[ ! -z "${data}" ]]
  then
    value=$(echo -e ${data} | jq --raw-output .[].Value 2> /dev/null)

    if [[ ! -z "${value}" ]]
    then
      echo ${value} | base64 -d
    else
      echo ""
      #echo "${decoded}"
    fi
  fi
}

