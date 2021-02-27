#!/bin/sh

cleanup_regdatabase() {
  while IFS= read -r chassis_id; do
    { 
      REGISTRY_ID=$(
        aws ssm get-parameter \
          --profile root \
          --region us-east-1 \
          --name "/metareg/$chassis_id/RegistryId" | jq -r '.Parameter.Value'
      )

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/metareg/$chassis_id/RegistryId" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/metareg/$chassis_id/CloudProvider" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/metareg/$chassis_id/Implementation" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/metareg/$chassis_id/RootComponentId" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/regdb/$REGISTRY_ID/ComponentId" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/regdb/$REGISTRY_ID/RootComponentId" &

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "/regdb/$REGISTRY_ID/Abstract" &

      aws logs delete-log-group \
        --profile root \
        --region us-east-1 \
        --log-group-name "/metareg/$chassis_id/regdatabase" &
    };
  done < chassis_list
}

cleanup_chassis_list() {
  while IFS= read -r chassis_id; do
    { 
      SSM_PARAMNAME="/chassis/$chassis_id"

      aws ssm delete-parameter \
        --profile root \
        --region us-east-1 \
        --name "$SSM_PARAMNAME" &

        sed -i '1d' chassis_list
    };
  done < chassis_list
}

main () {
  cleanup_regdatabase
  cleanup_chassis_list

  rm chassis_list chassis_last_registered
}

main