#!/bin/bash
# Setup PRODUCTION Project
if [ "$#" -ne 12 ]; then
    echo "Usage:"
    echo "  $0 PROD_NAMESPACE GAV[com.redhat:basic-kjar:1.0.0] APP_NAME(basic) EXTERNAL_DB_HOST EXTERNAL_DB EXTERNAL_DB_USER EXTERNAL_DB_PWD ENV[DEV,QA,SIT,UAT,PRE-PROD,PROD]] KIE_SERVER_IMAGE_STREAM_NAME IMAGE_STREAM_TAG KIE_KEYSTORE_PASS SETTINGS_XML_LOCATION[/home/.m2/settings.xml]"
    exit 1
fi

PRODNAMESPACE=$1
GAV=$2
APP_NAME=$3
EXTERNAL_DB_HOST=$4
EXTERNAL_DB=$5
EXTERNAL_DB_USER=$6
EXTERNAL_DB_PWD=$7
ENV=$8
KIE_SERVER_IMAGE_STREAM_NAME=$9
IMAGE_STREAM_TAG=${10}
KIE_KEYSTORE_PASS=${11}
SETTINGS_XML_LOCATION=${12}
echo "Setting up RH PAM PRODUCTION Environment in project ${PROD_NAMESPACE}"


echo "#################################################################################################"
echo " Expects secret for KIE Server KIE_SERVER_HTTPS_SECRET --> kieserver-app-secret and KIE_SERVER_HTTPS_KEYSTORE --> keystore.jks"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates73/secrets/bckeystore.jks"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates73/secrets/kiekeystore.jks"
echo "#################################################################################################"

#oc create secret generic businesscentral-app-secret --from-file=./Infrastructure/templates73/secrets/bckeystore.jks -n ${PROD_NAMESPACE}
#oc create secret generic kieserver-app-secret --from-file=./Infrastructure/templates73/secrets/kiekeystore.jks -n ${PROD_NAMESPACE}

echo ""
echo ""
echo "#################################################################################################"
echo " Configure the settings.xml to be used to download RHPAM Artifacts proxied by nexus in tools namespace"
echo "#################################################################################################"
echo ""

echo "create configmap to contain location of the NEXUS mirror and repositories to be used by RHPAMCENTRAL and KIE SERVER for artifact downloads"
oc create configmap settings.xml --from-file $SETTINGS_XML_LOCATION

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
echo "     <url>${NEXUS_ROUTE_URL}/repository/bpm-releases</url>"
echo "   </repository>"
echo "   <snapshotRepository>"
echo "     <id>nexu</id>"
echo "     <url>${NEXUS_ROUTE_URL}/repository/bpm-snapshots</url>"
echo "   </snapshotRepository>"
echo " </distributionManagement>"

echo ""
echo ""
echo "#################################################################################################"
echo " Configure RHPAM & KIESERVER (managed, non clustered, hypersonic db) without RHSSO integration" 
echo ""
echo " RHPAM Login: rhpamadmin/rhpamadmin730 "
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
#oc new-app --template=rhpam73-prod-external-oracle-stelios-1  -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret  -p APPLICATION_NAME=${APP_NAME} -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral  -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass  -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks  -p KIE_SERVER_HTTPS_NAME=kieserver -p KIE_SERVER1_HOSTNAME_HTTP="${APP_NAME}-kieserver-cluster-group-1-${DEV_NAMESPACE}.${CLUSTER}" -p KIE_SERVER2_HOSTNAME_HTTP="${APP_NAME}-kieserver-cluster-group-2-${DEV_NAMESPACE}.${CLUSTER}" -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass   -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks  -p KIE_ADMIN_USER=rhpamadmin   -p KIE_ADMIN_PWD=rhpamadmin730   -p KIE_SERVER_USER=executionUser   -p KIE_SERVER_PWD=executionUser123   -p KIE_SERVER_CONTROLLER_USER=controllerUser   -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 -p MAVEN_REPO_URL=${NEXUS_ROUTE_URL}/maven-public  -p MAVEN_REPO_USERNAME=admin  -p MAVEN_REPO_PASSWORD=admin123  -p MAVEN_REPO_ID=maven-public -p SMART_ROUTER_CONTAINER_REPLICAS=1 -p KIE_SERVER_CONTAINER_REPLICAS=1  -p KIE_SERVER_IMAGE_STREAM_NAME=rhpam73-kieserver-oracle-openshift -p IMAGE_STREAM_TAG=1.1 -p KIE_SERVER_EXTERNALDB_DIALECT="org.hibernate.dialect.Oracle12cDialect" -p KIE_SERVER_EXTERNALDB_DB=${EXTERNAL_DB} -p KIE_SERVER_EXTERNALDB_SERVICE_HOST=${EXTERNAL_DB_HOST} -p KIE_SERVER_EXTERNALDB_SERVICE_PORT=4321 -p KIE_SERVER_EXTERNALDB_JNDI="java:/jboss/datasources/rhpam" -p KIE_SERVER_EXTERNALDB_DRIVER=oracle -p KIE_SERVER_EXTERNALDB_USER=${EXTERNAL_DB_USER} -p KIE_SERVER_EXTERNALDB_PWD=${EXTERNAL_DB_PWD} -p KIE_SERVER_EXTERNALDB_NONXA="false" -p KIE_SERVER_EXTERNALDB_MIN_POOL_SIZE=5 -p KIE_SERVER_EXTERNALDB_MAX_POOL_SIZE=10 -p KIE_SERVER_EXTERNALDB_CONNECTION_CHECKER="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker" -p KIE_SERVER_EXTERNALDB_EXCEPTION_SORTER="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter" -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION=10000 -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION_MILLIS="true" -l app=pam-${ENV} -n ${PROD_NAMESPACE}

oc new-app --template=rhpam76-kieserver-oracle-externaldb \
                    -p APPLICATION_NAME=${APP_NAME} \
                    -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret -p KIE_SERVER_HTTPS_KEYSTORE=keystore.jks -p KIE_SERVER_HTTPS_PASSWORD=${KIE_KEYSTORE_PASS} \
                    -p KIE_ADMIN_USER=rhpamadmin -p KIE_ADMIN_PWD=rhpamadmin \
                    -p KIE_SERVER_USER=executionUser -p KIE_SERVER_PWD=executionUser123  \
                    -p KIE_SERVER_MONITOR_USER=controllerUser -p KIE_SERVER_MONITOR_PWD=controllerUser123 \
                    -p KIE_SERVER_IMAGE_STREAM_NAME=$KIE_SERVER_IMAGE_STREAM_NAME -p IMAGE_STREAM_TAG=$IMAGE_STREAM_TAG 
                    -p KIE_SERVER_EXTERNALDB_DIALECT="org.hibernate.dialect.Oracle12cDialect" -p KIE_SERVER_EXTERNALDB_DB=${EXTERNAL_DB} -p KIE_SERVER_EXTERNALDB_SERVICE_HOST=${EXTERNAL_DB_HOST} \
                    -p KIE_SERVER_EXTERNALDB_SERVICE_PORT=4321 -p KIE_SERVER_EXTERNALDB_JNDI="java:/jboss/datasources/rhpam" -p KIE_SERVER_EXTERNALDB_DRIVER=oracle \
                    -p KIE_SERVER_EXTERNALDB_USER=${EXTERNAL_DB_USER} -p KIE_SERVER_EXTERNALDB_PWD=${EXTERNAL_DB_PWD} -p KIE_SERVER_EXTERNALDB_NONXA="false" -p KIE_SERVER_EXTERNALDB_MIN_POOL_SIZE=5 \
                    -p KIE_SERVER_EXTERNALDB_MAX_POOL_SIZE=10 -p KIE_SERVER_EXTERNALDB_CONNECTION_CHECKER="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleValidConnectionChecker" \
                    -p KIE_SERVER_EXTERNALDB_EXCEPTION_SORTER="org.jboss.jca.adapters.jdbc.extensions.oracle.OracleExceptionSorter" -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION=10000 \
                    -p KIE_SERVER_EXTERNALDB_BACKGROUND_VALIDATION_MILLIS="true"
                    -p KIE_SERVER_MODE=PRODUCTION=DEVELOPMENT
                    -p KIE_SERVER_CONTAINER_DEPLOYMENT=containerId=${GAV}  -l app=pam-${ENV} -n ${PROD_NAMESPACE}



