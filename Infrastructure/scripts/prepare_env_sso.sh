#!/bin/bash

echo "Setting up Openshift Templates/ImageStreams for RH-SSO"

declare -a resources=("sso70-image-stream.json "
  "sso71-image-stream.json"
  "sso72-image-stream.json"
  "sso72-https.json"
  "sso72-mysql-persistent.json"
  "sso72-mysql.json"
  "sso72-postgresql-persistent.json"
  "sso72-postgresql.json"
  "sso72-x509-https.json"
  "sso72-x509-mysql-persistent.json"
  "sso72-x509-postgresql-persistent.json")

for resource in "${resources[@]}"
do
  echo "inserting template/imagestream ${resource} in openshift namespace"
  oc replace -n openshift --force -f https://raw.githubusercontent.com/jboss-container-images/redhat-sso-7-openshift-image/rh-sso-7.2-v1.3.0/templates/${resource}
done
