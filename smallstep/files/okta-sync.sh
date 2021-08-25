#!/bin/bash
#
TOKEN=$(aws --region us-east-2 ssm get-parameter --name "/forumone/okta/read_only_okta_token" --with-decryption | jq -r '.Parameter.Value')

ID=$(curl -s -X GET \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
"https://forumone.okta.com/api/v1/groups?q={{ user }}" | jq -r '.[] | .id')

curl -s -X GET \
-H "Accept: application/json" \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
"https://forumone.okta.com/api/v1/groups/$ID/users" | jq -r '.[] | .profile.login'