#!/bin/sh

IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | tr -d '\n')

docker-entrypoint.sh agent                  \
  -advertise=${IP}                          \
  -client=0.0.0.0                           \
  -retry-join-ec2-region=${REGION}          \
  -retry-join-ec2-tag-key=${TAG_KEY}        \
  -retry-join-ec2-tag-value=${TAG_VALUE}    
