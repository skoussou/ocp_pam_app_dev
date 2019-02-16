#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 NAMESPACE CLUSTER"
    exit 1
fi

NAMESPACE=$1
CLUSTER=$2
echo "Setting up Nexus in project $NAMESPACE in cluster $CLUSTER"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ./Infrastructure/templates/nexus.yaml --param .....

# To be Implemented
echo
echo
echo "#####################################################################"
echo "importing image for nexus3:latest in $NAMESPACE"
echo "#####################################################################"

oc import-image openshift/nexus3:latest --from=docker.io/sonatype/nexus3:latest --confirm -n $NAMESPACE

# create volume claim
echo
echo
echo "#####################################################################"
echo "creating volume nexus-pvc for nexus3 in $NAMESPACE"
oc create -f ./Infrastructure/templates/nexus-pvc.yaml  -n $NAMESPACE
echo "#####################################################################"
# 
echo
echo
echo "#####################################################################"
echo "creating app APPLICATION_NAME=nexus3 in $NAMESPACE"
echo "#####################################################################"
#oc new-app -f ./Infrastructure/templates/nexus.yaml -p APPLICATION_NAME=nexus3 -p PROJECT_NAMESPACE=$GUID-nexus -p APPS_CLUSTER_HOSTNAME=apps.na39.openshift.opentlc.com -l app=nexus3 -n $NAMESPACE
oc new-app -f ./Infrastructure/templates/nexus.yaml -p APPLICATION_NAME=nexus3 -p PROJECT_NAMESPACE=$NAMESPACE -p APPS_CLUSTER_HOSTNAME=$CLUSTER -l app=nexus3 -n $NAMESPACE
# add claim to DC
# oc rollout pause dc nexus3
# oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc
# oc rollout resume dc nexus3

# setup repositories script
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
while : ; do
  echo "Checking if Nexus is Ready..."
  oc get pod -n $NAMESPACE|grep '\-1\-'|grep -v deploy|grep "1/1"
  [[ "$?" == "1" ]] || break
  echo "...no. Sleeping 10 seconds."
  sleep 10
done

sleep 2s

# annotate correctly the routes for console
echo
echo
echo "#####################################################################"
echo "annotating routes"
echo "#####################################################################"

oc delete route nexus3
oc delete route nexus-registry
#oc annotate route nexus-registry console.alpha.openshift.io/overview-app-route=false --overwrite -n $NAMESPACE
#oc annotate route nexus3 console.alpha.openshift.io/overview-app-route=true --overwrite -n $NAMESPACE
oc expose svc nexus3 -l app=nexus3

echo
echo
echo "#####################################################################"
echo "Configuring NEXUS"
echo "./Infrastructure/scripts/extras/configure_nexus3.sh admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n $NAMESPACE)"
echo "#####################################################################"

sleep 5

SCRIPT_PATH="./Infrastructure/scripts/extras/configure_nexus3.sh"
source "$SCRIPT_PATH"
. "$SCRIPT_PATH" admin admin123 http://$(oc get route nexus3 --template='{{ .spec.host }}' -n $NAMESPACE)

