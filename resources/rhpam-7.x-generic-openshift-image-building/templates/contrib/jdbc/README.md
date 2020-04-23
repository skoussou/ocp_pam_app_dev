# Build JDBC Driver images

This repository provide a common repository for building JDBC Driver images to extend existing JBoss EAP Openshift images using S2I.

Implemented driver configurations (JDBC Drivers are NOT included):

| Database  | DB Version         | JDBC Driver                                   |
|-----------|--------------------|-----------------------------------------------|
| IBM DB2   | 10.5               | db2jcc4-10.5.jar                              |
| Derby     | 10.12.1.1          | derby-10.12.1.1.jar, derbyclient-10.12.1.1.jar|
| MariaDB   | 10.2               | mariadb-java-client-2.2.5.jar                 |
| MS SQL    | 2016               | sqljdbc4-4.0.jar                              |
| Oracle DB | 12c R1, 12c R1 RAC | ojdbc7-12.1.0.1.jar                           |
| Sybase    | 16.0               | jconn4-16.0_PL05.jar                          |

## Build a driver image of your choice

* The script has the following options
```bash
../build.sh --artifact-repo="." --namespace=<YOUR-NAMESPACE|leave empty for openshift> --registry=<YOUR REGISTRY> --image-tag=<LATEST VERSION OF KIE SERVER IMAGE>
```

### Driver publicly available

* If a driver can be publicly downloaded it has a default value for the ARTIFACT_MVN_REPO argument of the Dockerfile (found in the individual $database_driver_image directories)

#### Build in local CRC
```bash
cd $database_driver_image
../build-MYLOCAL-CRC.sh --namespace=pam-prod --registry=default-route-openshift-image-registry.apps-crc.testing --image-tag=7.6.0
```

#### OCP CLUSTER
```bash
cd $database_driver_image
../build.sh --artifact-repo="." --namespace=pam-prod-oracle --registry=default-route-openshift-image-registry.apps-crc.testing --image-tag=7.6.0
```

### Drivers not publicly available

* If a driver *_cannot_* be publicly downloaded (eg. Oracle, Mysql, Mssql) add the driver either in a repository of your own or insert the JDBC 4 Driver in the individual $database_driver_image directory and mdify accordingly Dockerfile (found in the individual $database_driver_image directories) to COPY the driver in the image. See exampel in the *oracle_driver_image* directory)

#### Build in local CRC
```bash
cd $database_driver_image
../build-MYLOCAL-CRC.sh --artifact-repo="https://github.com/skoussou/ocp_pam_app_dev/tree/master/Infrastructure/resources/drivers/oracle" --namespace=pam-prod-oracle --registry=default-route-openshift-image-registry.apps-crc.testing --image-tag=7.6.0
```
#### OCP CLUSTER
```bash
cd $database_driver_image
../build.sh --artifact-repo="." --namespace=pam-prod-oracle --registry=default-route-openshift-image-registry.apps-crc.testing --image-tag=7.6.0
```


