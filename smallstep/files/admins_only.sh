#!/bin/bash

cat /etc/step-ssh-acl.json | jq -r '.sudoers[] | .name'
