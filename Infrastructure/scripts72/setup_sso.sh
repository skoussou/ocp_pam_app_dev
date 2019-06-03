#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "  $0 NAMESPACE [TRUE|FALSE]"
    exit 1
fi


NAMESPACE=$1
PERSISTENT=$2

if [ "$PERSISTENT" != "TRUE" ] && [ "$PERSISTENT" != "FALSE" ]; then
    echo "Usage:"
    echo "  $0 NAMESPACE [TRUE|FALSE]"
    exit 1
fi

echo "Setting up Nexus in project $NAMESPACE with PERSISTENCE=$PERSISTENT"

# Code to set up the RHSSO. It will need to
# - Create necessary secrets
# * Create SSO
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
echo "creating neccessary SSO secrets  for nexus3:latest in $NAMESPACE"
echo "#####################################################################"

# keytool -genkeypair -alias businesscentral -keyalg RSA -keystore bckeystore.jks -keysize 2048 -storepass mykeystorepass --dname "CN=skoussou,OU=Services,O=redhat.com,L=Raleigh,S=NC,C=US"
#keytool -genkeypair -alias kieserver -keyalg RSA -keystore kiekeystore.jks -keysize 2048 -storepass mykeystorepass --dname "CN=skoussou,OU=Services,O=redhat.com,L=Raleigh,S=NC,C=US"

#oc create secret generic businesscentral-app-secret --from-file=bckeystore.jks -n YOUR-NAMESPACE
#oc create secret generic kieserver-app-secret --from-file=kiekeystore.jks -n YOUR-NAMESPACE



# To be Implemented
echo
echo
echo "#####################################################################"
echo "creating SSO in $NAMESPACE with persistence = $PERSISTENT"
echo "#####################################################################"

if [ "$PERSISTENT" = "FALSE" ]; then
  echo 'Deploy EPHEPERAL sso'
  oc new-app --template=openshift/sso72-x509-https -p APPLICATION_NAME=cgd-sso -p SSO_ADMIN_USERNAME=ssoadmin -p SSO_ADMIN_PASSWORD=ssoadmin720! -l app=sso -n $NAMESPACE
fi
if [ "$PERSISTENT" = "TRUE" ]; then
  echo 'Deploy SSO with MySQL backing'
  oc new-app --template=openshift/sso72-x509-mysql-persistent  -p APPLICATION_NAME=cgd-sso -p SSO_ADMIN_USERNAME=ssoadmin -p SSO_ADMIN_PASSWORD=ssoadmin720! -l app=sso -n $NAMESPACE
fi














