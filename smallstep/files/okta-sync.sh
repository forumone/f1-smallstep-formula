#!/bin/bash
#
TOKEN=$(aws --region us-east-2 ssm get-parameter --name "/forumone/okta/read_only_okta_token" --with-decryption | jq -r '.Parameter.Value')

ID=$(aws ssm get-parameter --name /forumone/usaid-climatelinks/okta/groups/{{ user }} \
      --region us-east-2 --with-decryption --output text --query Parameter.Value)

curl -s -X GET \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
"https://forumone.okta.com/api/v1/groups/$ID/users" | jq -r '.[] | .profile.login'