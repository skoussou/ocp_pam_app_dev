#!/bin/bash
# Setup Development Project
if [ "$#" -ne 5 ]; then
    echo "Usage:"
    echo "  $0 DEV_NAMESPACE TOOLS_NAMESPACE APP_NAME CLUSTER NEXUS_ROUTE_NAME"
    exit 1
fi

DEV_NAMESPACE=$1
TOOLS_NAMESPACE=$2
APP_NAME=$3
CLUSTER=$4
NEXUS_ROUTE_NAME=$5
echo "Setting up RH PAM Development Environment in project ${DEV_NAMESPACE}"


echo "#################################################################################################"
echo " Create secrets for Business Central & KIE Servers based on pre-prepared keystores"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates76/secrets/bckeystore.jks"
echo " Business Central keystore: ocp_pam_app_dev/Infrastructure/templates76/secrets/kiekeystore.jks"
echo "#################################################################################################"

oc create secret generic businesscentral-app-secret --from-file=./Infrastructure/templates76/secrets/bckeystore.jks -n ${DEV_NAMESPACE}
oc create secret generic kieserver-app-secret --from-file=./Infrastructure/templates76/secrets/kiekeystore.jks -n ${DEV_NAMESPACE}

echo ""
echo ""
echo "#################################################################################################"
echo " Configure the settings.xml to be used to download RHPAM Artifacts proxied by nexus in tools namespace"
echo "#################################################################################################"
echo ""

NEXUS_ROUTE_URL=http://$(oc get route $NEXUS_ROUTE_NAME --template='{{ .spec.host }}' -n $TOOLS_NAMESPACE)
#NEXUS_ROUTE_URL=http://$(oc get route nexus --template='{{ .spec.host }}' -n $TOOLS_NAMESPACE)
echo "NEXUS_ROUTE_URL=$NEXUS_ROUTE_URL"
sed -i "s@URL@${NEXUS_ROUTE_URL}/repository/maven-all-public/@" ./Infrastructure/templates76/settings.xml

echo "create configmap to contain location of the NEXUS mirror and repositories to be used by RHPAMCENTRAL and KIE SERVER for artifact downloads"
oc create configmap settings.xml --from-file ./Infrastructure/templates76/settings.xml

# Reset back to URL in case need to change for PROD
sed -ie "s@${NEXUS_ROUTE_URL}/repository/maven-all-public/@URL@g" ./Infrastructure/templates76/settings.xml

echo "Distribution management for RHPAM projects"
echo ""
echo "The setup utilizes RHPAM Central internal GIT Repo as source of truth (not recommended for final instalation)"
echo "The setup expects manual via RHPAM Central build and deployment of PAM Projects via distribution to the NEXUS server"
echo ""
echo "All new projects created in RHPAM Central will have to be modifed so that POM.XML contains the following sections"
echo ""
echo " <distributionManagement>"
echo "   <repository>"
echo "     <id>Nexus</id>"
echo "     <url>${NEXUS_ROUTE_URL}/repository/maven-releases</url>"
echo "   </repository>"
echo "   <snapshotRepository>"
echo "     <id>Nexus</id>"
echo "     <url>${NEXUS_ROUTE_URL}/repository/maven-snapshots</url>"
echo "   </snapshotRepository>"
echo " </distributionManagement>"

echo ""
echo ""
echo "#################################################################################################"
echo " Configure RHPAM & KIESERVER (managed, non clustered, hypersonic db) without RHSSO integration" 
echo ""
echo " RHPAM Login: rhpamadmin/rhpamadmin760 "
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

oc new-app --template=rhpam76-authoring-managed -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret  \
           -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret -p APPLICATION_NAME=${APP_NAME} -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral \
           -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks -p KIE_SERVER_HTTPS_NAME=kieserver \
           -p KIE_SERVER_HOSTNAME_HTTP="${APP_NAME}-${DEV_NAMESPACE}.${CLUSTER}" -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass  \
           -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks -p KIE_ADMIN_USER=rhpamadmin -p KIE_ADMIN_PWD=rhpamadmin760 -p KIE_SERVER_USER=executionUser \
           -p KIE_SERVER_PWD=executionUser123 -p KIE_SERVER_CONTROLLER_USER=controllerUser -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 \
           -p MAVEN_REPO_URL=${NEXUS_ROUTE_URL}/maven-public -p MAVEN_REPO_USERNAME=admin -p MAVEN_REPO_PASSWORD=admin123 -p MAVEN_REPO_ID=maven-public  \
           -l app=pam-${APP_NAME}-dev -n ${DEV_NAMESPACE}

echo ""
echo ""
echo "#################################################################################################"
echo " Configure SSO for the apps"
echo " TODO	BUSINESS CENTRAL ... send JSON for ${APP_NAME}-rhpamcentral client creation - TYPE: confidentiality"
echo " TODO	BUSINESS CENTRAL ... send JSON for ${APP_NAME}-rhpamcentral client creation - TYPE: token bearer"
echo " TODO	curl ... send JSON for ${APP_NAME}-rhpamcentral client creation - TYPE: confidentiality"
echo "#################################################################################################"

echo ""
echo ""
echo "#################################################################################################"
echo " Configure RHPAM & KIESERVER (managed, non clustered, hypersonic db) with RHSSO integration" 
echo ""
echo " RHPAM Login: rhpamadmin/rhpamadmin760 "
echo ""
echo ""
echo " User management: for execution" 
echo " 		- initial credentials: executionUser/executionUser123 roles: kie-server,rest-all,guest"
echo ""
echo "          - example adding new user (JSON, REMOTE COMMAND, to realm and client with variable roles"
echo "#################################################################################################"
echo ""

#SSO_ROUTE_URL=http://$(oc get route cgd-sso --template='{{ .spec.host }}' -n $TOOLS_NAMESPACE)

echo "URL to authenticate with SSO $SSO_ROUTE_URL/auth with ssoadmin/ssoadmin760!"
echo ""
echo "removed creation until RHSSO issue corrected"
#oc new-app --template=stelios-1-rhpam72-authoring -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret  -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret -p APPLICATION_NAME=cgd -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks -p KIE_SERVER_HTTPS_NAME=kieserver -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass  -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks -p KIE_ADMIN_USER=rhpamadmin -p KIE_ADMIN_PWD=rhpamadmin720 -p KIE_SERVER_USER=executionUser -p KIE_SERVER_PWD=executionUser123 -p KIE_SERVER_CONTROLLER_USER=controllerUser -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 -p MAVEN_REPO_URL=${NEXUS_ROUTE_URL}/maven-public -p MAVEN_REPO_USERNAME=admin -p MAVEN_REPO_PASSWORD=admin123 -p MAVEN_REPO_ID=maven-public  -p SSO_URL=${SSO_ROUTE_URL}/auth -p SSO_REALM=master -p BUSINESS_CENTRAL_SSO_CLIENT=cgd-rhpamcentral -p BUSINESS_CENTRAL_SSO_SECRET=05a6816a-9161-49a9-875b-ad3f898a6264 -p KIE_SERVER_SSO_CLIENT=cgd-kieserver -p SSO_USERNAME=ssoadmin -p SSO_PASSWORD=ssoadmin720! -p SSO_DISABLE_SSL_CERTIFICATE_VALIDATION=true -l app=bc -n pam-dev
			




#########################################################################
#
#	ORIGINAL COMMANDS created manually environment
#
#########################################################################
#	oc new-app --template=stelios-1-rhpam72-authoring \
#                       -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret  \
#                       -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret \
#                       -p APPLICATION_NAME=cgd \
#                       -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral \
#                       -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass \
#                       -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks \
#                       -p KIE_SERVER_HTTPS_NAME=kieserver \
#                       -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass  \
#                       -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks \
#                       -p KIE_ADMIN_USER=rhpamadmin \
#                       -p KIE_ADMIN_PWD=rhpamadmin720 \
#                       -p KIE_SERVER_USER=executionUser \
#                       -p KIE_SERVER_PWD=executionUser123 \
#                       -p KIE_SERVER_CONTROLLER_USER=controllerUser \
#                       -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 \
#                       -p MAVEN_REPO_URL=http://nexus3-tools.192.168.42.21.nip.io/maven-public \
#                       -p MAVEN_REPO_USERNAME=admin \
#                       -p MAVEN_REPO_PASSWORD=admin123 \
#                       -p MAVEN_REPO_ID=maven-public  \
#                       -p SSO_URL=https://sso-tools.192.168.42.21.nip.io/auth \
#                       -p SSO_REALM=master \
#                       -p BUSINESS_CENTRAL_SSO_CLIENT=cgd-rhpamcentral \
#                       -p BUSINESS_CENTRAL_SSO_SECRET=05a6816a-9161-49a9-875b-ad3f898a6264 \
#                       -p KIE_SERVER_SSO_CLIENT=cgd-kieserver \
#                       -p SSO_USERNAME=ssoadmin \
#                       -p SSO_PASSWORD=ssoadmin720! \
#                       -p SSO_DISABLE_SSL_CERTIFICATE_VALIDATION=true -l app=bc -n pam-dev
#			
#
#
#	oc new-app --template=stelios-1-rhpam72-authoring \
#                       -p BUSINESS_CENTRAL_HTTPS_SECRET=businesscentral-app-secret  \
#                       -p KIE_SERVER_HTTPS_SECRET=kieserver-app-secret \
#                       -p APPLICATION_NAME=cgd \
#                       -p BUSINESS_CENTRAL_HTTPS_NAME=businesscentral \
#                       -p BUSINESS_CENTRAL_HTTPS_PASSWORD=mykeystorepass \
#                       -p BUSINESS_CENTRAL_HTTPS_KEYSTORE=bckeystore.jks \
#                       -p KIE_SERVER_HTTPS_NAME=kieserver \
#                       -p KIE_SERVER_HTTPS_PASSWORD=mykeystorepass  \
#                       -p KIE_SERVER_HTTPS_KEYSTORE=kiekeystore.jks \
#                       -p KIE_ADMIN_USER=rhpamadmin \
#                       -p KIE_ADMIN_PWD=rhpamadmin720 \
#                       -p KIE_SERVER_USER=executionUser \
#                       -p KIE_SERVER_PWD=executionUser123 \
#                       -p KIE_SERVER_CONTROLLER_USER=controllerUser \
#                       -p KIE_SERVER_CONTROLLER_PWD=controllerUser123 \
#                       -p MAVEN_REPO_URL=http://nexus3-tools.192.168.42.21.nip.io/maven-public \
#                       -p MAVEN_REPO_USERNAME=admin \
#                       -p MAVEN_REPO_PASSWORD=admin123 \
#                       -p MAVEN_REPO_ID=maven-public  -l app=bc -n pam-dev
			


















