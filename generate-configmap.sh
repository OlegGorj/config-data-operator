#!/bin/bash

CONFIG_SERVICE_URL=$1
MAINPATH=$2 # /opt/ansible/
BUILD_TIME=$(date -u '+%Y-%m-%d_%H:%M:%S')

# get list of number of configurations
CONFIGS_NUM=$(curl -X GET ${CONFIG_SERVICE_URL}/api/v2/configmaps/sandbox/@ -H 'Cache-Control: no-cache')
i=0
while [ $i -lt ${CONFIGS_NUM} ]
do
  CONF_JSON=$(curl -X GET ${CONFIG_SERVICE_URL}/api/v2/configmaps/sandbox/${i} -H 'Cache-Control: no-cache')
  #echo $CONF_JSON

  NAMESPACE=$(echo $CONF_JSON | jq '.namespace' | tr -d '"' )
  CONFIGMAP=$(echo $CONF_JSON | jq '.configmap' | sed 's/.json//g' | tr -d '"' )
  CONFIG=$(echo $CONF_JSON | jq '.config' | sed 's/.json//g' | tr -d '"' )
  # create list of keys in format <.keys.*.config_service_key>|<.keys.*.configmap_key>
  # declare -a list=( $( echo $CONF_JSON | jq -c '.keys | .[].config_service_key' | tr -d '"' )    )
  declare -a list=( $(echo $CONF_JSON | jq -c '.keys[] | .config_service_key + "|" + .configmap_key' | tr -d '"') )

  # first, generate configmap from template
  yq  --arg var ${CONFIGMAP}  '.metadata.name = ($var) ' ${MAINPATH}/configmap.template > ${MAINPATH}/configmap_${CONFIGMAP}.json
  # set the namespace
  echo $(yq  --arg var ${NAMESPACE}  '.metadata.namespace = ($var) ' ${MAINPATH}/configmap_${CONFIGMAP}.json) > ${MAINPATH}/configmap_${CONFIGMAP}.json
  # itterate through list of keys
  for element in "${list[@]}"
  do
    URL="${CONFIG_SERVICE_URL}/api/v2/${CONFIG}/sandbox/$(echo ${element} | cut -f1 -d'|')" && CONF_VAL=$(curl -X GET ${URL} )
    # add key to 'data' section
    echo $(yq --arg key $(echo ${element} | cut -f2 -d'|') --arg val $(echo $CONF_VAL | base64)  '.data |= . + { ($key) : ($val) } ' ${MAINPATH}/configmap_${CONFIGMAP}.json) > ${MAINPATH}/configmap_${CONFIGMAP}.json
  done

  echo "---" > ${MAINPATH}/configmap_${CONFIGMAP}.yaml \
  && yq --yaml-output '.' ${MAINPATH}/configmap_${CONFIGMAP}.json >> ${MAINPATH}/configmap_${CONFIGMAP}.yaml \
  && rm ${MAINPATH}/configmap_${CONFIGMAP}.json

  ((i++))
done

cat ${MAINPATH}/configmap_*.yaml > ${MAINPATH}/configmap.yaml && rm -f configmap_*.yaml

echo "********** end of the script *********"
