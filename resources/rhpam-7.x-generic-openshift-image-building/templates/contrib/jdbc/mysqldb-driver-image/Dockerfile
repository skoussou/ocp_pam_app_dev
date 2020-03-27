FROM scratch

LABEL   maintainer="stelios@redhat.com" \
        name="MysqlB JDBC Driver" \
        version="5.1.18"

# Provide the right value during build
ARG ARTIFACT_MVN_REPO

COPY install.sh mysqldb-driver-image/install.properties /extensions/
COPY mysqldb-driver-image/modules /extensions/modules/
     
# Download the driver into the module folder
ADD ${ARTIFACT_MVN_REPO}/com/mysql/jdbc/mysql-connector-java/5.1.18/mysql-connector-java-5.1.18.jar \
/extensions/modules/system/layers/openshift/com/mysql/main/mysql-connector-java-5.1.18.jar
