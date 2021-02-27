#!/bin/bash

CHASSIS_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1) 
LOGGROUP_NAME="/metareg/$CHASSIS_ID/regdatabase"

get_isodate() {
  unset ISODATE
  ISODATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
}

get_unixtimestamp() {
  unset UNIXTIMESTAMP
  UNIXTIMESTAMP=$(date +%s%3N)
}

putlogevent() {
  EVENTS_JSONLIKE=$(cat events)

  echo "[$EVENTS_JSONLIKE]" > events.json

  if [[ ! -z "$NEXTSEQUENCETOKEN" ]]
  then
    NEXTSEQUENCETOKEN=$(
      aws logs put-log-events \
        --profile root \
        --region us-east-1 \
        --log-group-name "$LOGGROUP_NAME" \
        --log-stream-name "/stdout" \
        --sequence-token "$NEXTSEQUENCETOKEN" \
        --log-events file://events.json | jq -r '.nextSequenceToken'
    )
  else
    NEXTSEQUENCETOKEN=$(
      aws logs put-log-events \
        --profile root \
        --region us-east-1 \
        --log-group-name "$LOGGROUP_NAME" \
        --log-stream-name "/stdout" \
        --log-events file://events.json | jq -r '.nextSequenceToken'
    )
  fi
}



create_loggroup_regdatabase_stdout() {
  get_unixtimestamp

  aws logs create-log-group \
    --profile root \
    --region us-east-1 \
    --log-group-name "$LOGGROUP_NAME"

  aws logs create-log-stream \
    --profile root \
    --region us-east-1 \
    --log-group-name "$LOGGROUP_NAME" \
    --log-stream-name "/stdout"

  cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Creating Log Group"
}
EOF

  putlogevent
}

registering_chassis() {
  {
    get_isodate

    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/chassis/$CHASSIS_ID" \
      --type "String" \
      --value "$CHASSIS_ID" \
      --overwrite

    cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Registering Chassis $CHASSIS_ID [$ISODATE]"
}
EOF

    putlogevent

    echo "$CHASSIS_ID" > chassis_last_registered
    echo "$CHASSIS_ID" >> chassis_list
  } >> registry_database.log 2>&1
}

create_registryid() {
  {
    REGISTRY_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
    get_isodate
    get_unixtimestamp

    cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Registering RegistryId $REGISTRY_ID (Chassis $CHASSIS_ID) [$ISODATE]"
}
EOF

    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/metareg/$CHASSIS_ID/RegistryId" \
      --type "String" \
      --value "$REGISTRY_ID" \
      --overwrite

    putlogevent
  } >> registry_database.log 2>&1
}

create_cloudprovider() {
  {
    get_isodate
    cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Registering CloudProvider (Chassis $CHASSIS_ID) [$ISODATE]"
}
EOF

    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/metareg/$CHASSIS_ID/CloudProvider" \
      --type "String" \
      --value "aws" \
      --overwrite

    putlogevent
  } >> registry_database.log 2>&1
}

create_implementation() {
  get_isodate
  
  cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Registering Implementation (Chassis $CHASSIS_ID) [$ISODATE]"
}
EOF
  {
    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/metareg/$CHASSIS_ID/Implementation" \
      --type "String" \
      --value "SSM" \
      --overwrite

    putlogevent
  } >> registry_database.log 2>&1
}

create_rootcomponentid() {
  get_isodate
  
  cat > events << EOF
{
  "timestamp": ${UNIXTIMESTAMP},
  "message": "Registering Root Component Id Registry (Chassis $CHASSIS_ID) [$ISODATE]"
}
EOF
  {
    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/metareg/$CHASSIS_ID/RootComponentId" \
      --type "String" \
      --value "null" \
      --overwrite

    putlogevent
  } >> registry_database.log 2>&1
}

create_regdb() {
  COMPONENT_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1) 

  {
    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/regdb/$REGISTRY_ID/ComponentId" \
      --type "String" \
      --value "$COMPONENT_ID" \
      --overwrite &

    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/regdb/$REGISTRY_ID/RootComponentId" \
      --type "String" \
      --value "null" \
      --overwrite &

    aws ssm put-parameter \
      --profile root \
      --region us-east-1 \
      --name "/regdb/$REGISTRY_ID/Abstract" \
      --type "String" \
      --value "true" \
      --overwrite &
  } >> registry_database.log 2>&1
}

main() {
  create_loggroup_regdatabase_stdout
  registering_chassis
  create_registryid
  create_cloudprovider
  create_implementation
  create_rootcomponentid

  create_regdb
  
  rm events events.json
}

main &