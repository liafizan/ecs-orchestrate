#!/bin/sh

IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 | tr -d '\n')
echo Running: registrator -ip $IP $@ consul://$IP:8500
exec registrator -ip $IP "$@" consul://$LOCAL_IP:8500
