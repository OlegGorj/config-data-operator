#!/bin/bash

# Script takes 2 arguments:
# - configuration service url in form: http://<ip>:<port>
# - local directory to store output yaml file (e.g. /tmp  )

exitscript () {
    echo >&2 "$@"
    exit 1
}

CONFIG_SERVICE_URL=$1
MAINPATH=$2 # /opt/ansible/
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')

[ "$#" -eq 2 ] || die "2 argument required, $# provided"

# get list of number of configurations
CONFIGS_NUM=$(curl -X GET ${CONFIG_SERVICE_URL}/api/v2/configmaps/sandbox/@ -H 'Cache-Control: no-cache')
i=0
while [ $i -lt ${CONFIGS_NUM} ]
do
  CONF_JSON=$(curl -X GET ${CONFIG_SERVICE_URL}/api/v2/configmaps/sandbox/${i} -H 'Cache-Control: no-cache')
  #echo $CONF_JSON
  # check if returned value is in fact JSON
  if jq -e . >/dev/null 2>&1 <<<"$CONF_JSON"; then
      echo "Parsed JSON successfully"
  else
      echo "Failed to parse JSON, or got false/null"
  fi

  NAMESPACE=$(echo $CONF_JSON | jq '.namespace' | tr -d '"' )
  CONFIGMAP=$(echo $CONF_JSON | jq '.configmap' | sed 's/.json//g' | tr -d '"' )
  CONFIG=$(echo $CONF_JSON | jq '.config' | sed 's/.json//g' | tr -d '"' )
  # create list of keys
  #  keys formated as  <.keys.*.config_service_key>|<.keys.*.configmap_key>
  declare -a list=( $(echo $CONF_JSON | jq -c '.keys[] | .config_service_key + "|" + .configmap_key' | tr -d '"') )

  # first, generate configmap from template
  yq  --arg var ${CONFIGMAP}  '.metadata.name = ($var) ' ${MAINPATH}/configmap.template > ${MAINPATH}/configmap_${CONFIGMAP}.json
  # set the namespace
  echo $(yq  --arg var ${NAMESPACE}  '.metadata.namespace = ($var) ' ${MAINPATH}/configmap_${CONFIGMAP}.json) > ${MAINPATH}/configmap_${CONFIGMAP}.json
  # itterate through list of keys
  for element in "${list[@]}"
  do
    # make curl call to config service to get key's value
    # to get the key from the list: $(echo ${element} | cut -f1 -d'|')
    URL="${CONFIG_SERVICE_URL}/api/v2/${CONFIG}/sandbox/$(echo ${element} | cut -f1 -d'|')" && CONF_VAL=$(curl -X GET ${URL} )
    # add key to 'data' section
    echo $(yq --arg key $(echo ${element} | cut -f2 -d'|') --arg val $(echo $CONF_VAL | base64)  '.data |= . + { ($key) : ($val) } ' ${MAINPATH}/configmap_${CONFIGMAP}.json) > ${MAINPATH}/configmap_${CONFIGMAP}.json
  done
  # construct yaml file for each configuration
  echo "---" > ${MAINPATH}/configmap_${CONFIGMAP}.yaml \
    && yq --yaml-output '.' ${MAINPATH}/configmap_${CONFIGMAP}.json >> ${MAINPATH}/configmap_${CONFIGMAP}.yaml \
    && rm ${MAINPATH}/configmap_${CONFIGMAP}.json

  ((i++))
done

cat ${MAINPATH}/configmap_*.yaml > ${MAINPATH}/configmap.yaml && rm -f configmap_*.yaml

echo "********** end of the script *********"
