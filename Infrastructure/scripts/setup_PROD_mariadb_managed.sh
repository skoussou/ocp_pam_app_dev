#!/bin/bash
# Setup PRODUCTION Project
if [ "$#" -ne 6 ]; then
    echo "Usage:"
    echo "  $0 PROD_NAMESPACE TOOLS_NAMESPACE EXTERNAL_DB_HOST EXTERNAL_DB EXTERNAL_DB_USER EXTERNAL_DB_PWD"
    exit 1
fi

PROD_NAMESPACE=$1
TOOLS_NAMESPACE=$2
EXTERNAL_DB_HOST=$3
EXTERNAL_DB=$4
EXTERNAL_DB_USER=$5
EXTERNAL_DB_PWD=$6
echo "Setting up RH PAM PRODUCTION Environment in project ${PROD_NAMESPACE}"


echo "#################################################################################################"
echo " Create secrets for Business Central & KIE Servers based on pre-prepared keystores"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates/secrets/bckeystore.jks"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates/secrets/kiekeystore.jks"
echo "#################################################################################################"

oc create secret generic businesscentral-app-secret --from-file=./Infrastructure/templates/secrets/bckeystore.jks -n ${PROD_NAMESPACE}
oc create secret generic kieserver-app-secret --from-file=./Infrastructure/templates/secrets/kiekeystore.jks -n -n ${PROD_NAMESPACE}

echo ""
echo ""
echo "#################################################################################################"
echo " Configure the settings.xml to be used to download RHPAM Artifacts proxied by nexus in tools namespace"
echo "#################################################################################################"
echo ""

NEXUS_ROUTE_URL=http://$(oc get route nexus3 --template='{{ .spec.host }}' -n $TOOLS_NAMESPACE)
echo "NEXUS_ROUTE_URL=$NEXUS_ROUTE_URL"

# Add NEXUS URL 
sed -ie "s@URL@${NEXUS_ROUTE_URL}/repository/maven-all-public/@g" ./Infrastructure/templates/settings.xml

echo "create configmap to contain location of the NEXUS mirror and repositories to be used by RHPAMCENTRAL and KIE SERVER for artifact downloads"
oc create configmap settings.xml --from-file ./Infrastructure/templates/settings.xml

# Reset back to URL in case need to change for PROD
sed -ie "s@${NEXUS_ROUTE_URL}/repository/maven-all-public/@URL@g" ./Infrastructure/templates/settings.xml

echo "Distribution management for RHPAM projects"
echo ""
echo "The setup utilizes RHPAM Central internal GIT Repo as source of truth (not recommended for final instalation)"
echo "The setup expects manual via RHPAM Central build and deployment of PAM Projects via distribution to the NEXUS server"
echo ""
echo "All new projects created in RHPAM Central will have to be modifed so that POM.XML contains the following sections"
echo ""
echo " <distributionManagement>"
echo "   <repository>"
echo "     <id>nexu</id>"
echo "     <url>${NEXUS_ROUTE_URL}/repository/maven-releases</url>"
echo "   </repository>"
echo "   <snapshotRepository>"
echo "     <id>nexu</id>"
echo "     <url>${NEXUS_ROUTE_URL}/repository/maven-snapshots</url>"
echo "   </snapshotRepository>"
echo " </distributionManagement>"

echo ""
echo ""
echo "#################################################################################################"
echo " Configure RHPAM & KIESERVER (managed, non clustered, hypersonic db) without RHSSO integration" 
echo ""
echo " RHPAM Login: rhpamadmin/rhpamadmin720 "
echo ""
echo " User management: for execution"
echo " 		- credentials: executionUser/executionUser123 roles: kie-server,rest-all,guest"
echo " Further users: "
echo "		- Step 1: Add to business central"
echo "		     oc rsh <rhpamcentral POD>"
echo "               cd /opt/eap/bin"
echo "               ./add-user.sh -a -u <user-name> -p <password> -g kie-server,rest-all,<YOUR ROLE from Business Process>,<analyst: if user to start process from business central>"
echo "		- Step 2: Add same user to kieserver"
echo "		     oc rsh <kieserver POD>"
echo "               cd /opt/eap/bin"
echo "               ./add-user.sh -a -u <user-name> -p <password> -g kie-server,rest-all,<YOUR ROLE from Business Process>"
echo "#################################################################################################"
echo ""
oc new-app --template=rhpam72-prod-external-mariadb-stelios-1  -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret  -p APPLICATION_NAME=cgd-retail -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral  -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass  -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks  -p KIE_SERVER_HTTPS_NAME=kieserver  -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass   -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks  -p KIE_ADMIN_USER=rhpamadmin   -p KIE_ADMIN_PWD=rhpamadmin720   -p KIE_SERVER_USER=executionUser   -p KIE_SERVER_PWD=executionUser123   -p KIE_SERVER_CONTROLLER_USER=controllerUser   -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 -p MAVEN_REPO_URL=${NEXUS_ROUTE_URL}/maven-public  -p MAVEN_REPO_USERNAME=admin  -p MAVEN_REPO_PASSWORD=admin123  -p MAVEN_REPO_ID=maven-public -p SMART_ROUTER_CONTAINER_REPLICAS=1 -p KIE_SERVER_CONTAINER_REPLICAS=1  -p KIE_SERVER_IMAGE_STREAM_NAME=rhpam72-kieserver-mariadb-openshift -p IMAGE_STREAM_TAG=1.1 -p KIE_SERVER_EXTERNALDB_DIALECT="org.hibernate.dialect.MySQL5Dialect" -p KIE_SERVER_EXTERNALDB_DB=${EXTERNAL_DB} -p KIE_SERVER_EXTERNALDB_SERVICE_HOST=${EXTERNAL_DB_HOST} -p KIE_SERVER_EXTERNALDB_SERVICE_PORT=3306 -p KIE_SERVER_EXTERNALDB_JNDI="java:/jboss/datasources/rhpam" -p KIE_SERVER_EXTERNALDB_DRIVER=mysql -p KIE_SERVER_EXTERNALDB_USER=${EXTERNAL_DB_USER} -p KIE_SERVER_EXTERNALDB_PWD=${EXTERNAL_DB_PWD} -p KIE_SERVER_EXTERNALDB_NONXA="false" -p KIE_SERVER_EXTERNALDB_MIN_POOL_SIZE=5 -p KIE_SERVER_EXTERNALDB_MAX_POOL_SIZE=10 -p KIE_SERVER_EXTERNALDB_CONNECTION_CHECKER="org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLValidConnectionChecker" -p KIE_SERVER_EXTERNALDB_EXCEPTION_SORTER="org.jboss.jca.adapters.jdbc.extensions.mysql.MySQLExceptionSorter" -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION=10000 -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION_MILLIS="true" -l app=pamprod -n ${PROD_NAMESPACE}


echo ""
echo ""
echo "#################################################################################################"
echo " Configure SSO for the apps"
echo " TODO	BUSINESS CENTRAL ... send JSON for cgd-rhpamcentral client creation - TYPE: confidentiality"
echo " TODO	BUSINESS CENTRAL ... send JSON for cgd-rhpamcentral client creation - TYPE: token bearer"
echo " TODO	curl ... send JSON for cgd-rhpamcentral client creation - TYPE: confidentiality"
echo "#################################################################################################"

echo ""
echo ""
echo "#################################################################################################"
echo " Configure RHPAM & KIESERVER (managed, non clustered, hypersonic db) with RHSSO integration" 
echo ""
echo " RHPAM Login: rhpamadmin/rhpamadmin720 "
echo ""
echo ""
echo " User management: for execution" 
echo " 		- initial credentials: executionUser/executionUser123 roles: kie-server,rest-all,guest"
echo ""
echo "          - example adding new user (JSON, REMOTE COMMAND, to realm and client with variable roles"
echo "#################################################################################################"
echo ""
SSO_ROUTE_URL=http://$(oc get route cgd-sso --template='{{ .spec.host }}' -n $TOOLS_NAMESPACE)

echo "URL to authenticate with SSO $SSO_ROUTE_URL/auth with ssoadmin/ssoadmin720!"
echo ""
echo "removed creation until RHSSO issue corrected"




