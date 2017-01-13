-------------------------------------------------------------------------
ECS orchestration
:-
  This tool provisions your stack on ECS clusters
  Also packaged are dockerfiles for consul-client, consul-master and registrator

Prereqs:
1. An ECS cluster containing minimum one instance
2. Instances should have ECS agent along with docker running on instances
3. Each containe is allocated 100 cpu cycles and 2G-hard/1G-soft memory by default. Instances should be capable enough to handle the requirements
4. If a service exists, it cannot be recreated to achieve idempotency. It has to be updated using update option


Tool usage:
usage: orchestrate.py [-h] [-r REGION] [-u UUID] [-f CONFFILE] [-c COUNT] [-v]
                      [-e ENV] (--create | --update | --delete)

Arguments for managing GLP-services with ecs

optional arguments:
  -h, --help   show this help message and exit
  -r REGION    OPTIONAL: Region. Default is us-east-2
  -f CONFFILE  OPTIONAL: Config to pass for parsing.
  -c COUNT     OPTIONAL: Count for scaling up or down, If not specified, will
               be picked from update conf file
  -v           OPTIONAL: Verbose flag
  -e ENV       OPTIONAL: Target environment [ dev,qa,stage ]. Default is dev
  --create     REQUIRED/EXCLUSIVE : Create a service from task definition
  --update     REQUIRED/EXCLUSIVE : Update a service. [ task defs, container
               count etc]
  --delete     REQUIRED/EXCLUSIVE : Delete a service from specified cluster

----------------------------------------------------------------------------

Main files: 

Script works in two different modes: 
   -  Single file : Specify individual config file name and service will be updated for one single file
   -  Multiple files: Do not specify any file and any file in base directory will be processesed. 

NOTE: Base directory is ${SCRIPT_DIR}/config/


-------------------------------------Lambda-service-------------------------

This utility will also be used by aws-lambda-service to launch lm-services for every learner coming to the platform


application-code -> SNS -> lambda -> ecs-trigger
----------------------------------------------------------------------------

Example yaml:

#****************************************************************************************
# Yaml formate to manage entire lifcycle of containers
# We define four stages as of now viz:
# 1. Tak registration
# 2. Service creation
# 3. Service updates
# 4. Service deletion
# Assumption:
#      - Images are available in ECR repo or docker-hub
#      - Cluster is up and running with container instances
# More information : http://boto3.readthedocs.io/en/latest/reference/services/ecs.html
# *****************************************************************************************
containers:
  - appname: Test
    family: TEST
    taskRoleArn: ''
    containerDefinitions:
     - cpu: 200
       memory: 2048
       memoryReservation: 1024
       portMappings:
         - hostPort: 0
           containerPort: 9080
       # We can use docker-hub images as well
       image: 953030164212.dkr.ecr.us-east-1.amazonaws.com/test-service
       name: test
       essential: True
       privileged: False
       mountPoints:
       - sourceVolume: logs
         containerPath: /var/log/test-app/
         readOnly: False
       environment:
          - name : APP_ENV
            value: dev
          - name: CONF_HOME
            value: /opt/apps-java/config
          # This environment variable is for registrator to identify service
          - name: SERVICE_NAME
            value: test
       dockerLabels:
           name: test-service-containers
       dockerSecurityOptions:
           - no-new-privileges
    volumes:
      - name: logs
        host:
          sourcePath: /var/log/apps/
    # ***********************************************************************************************************
    # Service parameters will be used to create service
    # We can add load balancers alo if required.
    # Please visit : http://boto3.readthedocs.io/en/latest/reference/services/ecs.html#ECS.Client.create_service
    # ***********************************************************************************************************
    serviceCreate:
      - cluster: applications-dev
        serviceName: test-service
        # Task definition is family:revision.
        # Creat service on latest revision and use update to roll back o deploy new version
        taskDefinition: TEST
        desiredCount: 2
        clientToken: test-service
        deploymentConfiguration:
           maximumPercent: 200
           minimumHealthyPercent: 50
    # ******************************************************************
    # Service Update parameters will be used to update running service
    # ******************************************************************
    serviceUpdate:
      - cluster: applications-dev
        serviceName: test-service
        # Desired count also can be updated via commandlinee
        desiredCount: 2
        # Specify task def revision to roll back
        taskDefinition: TEST
        deploymentConfiguration:
           maximumPercent: 200
           minimumHealthyPercent: 50
    # **********************************************************************
    # Service dlete will be used to delete services where running count is 0
    # Cannot be used via automated tools as it requires user confimration
    # **********************************************************************
    serviceDelete:
      - cluster:  applications-dev
        serviceName: test-service

