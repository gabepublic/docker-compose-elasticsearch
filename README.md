# docker-compose-elasticsearch

Using docker compose to define a multi-container application that are running 
in a network created specifically for the application.

## SUMMARY

- The example demonstrates a multi-container docker application that is deployed
  using docker-compose; the ElasticSearch container and the website container.
  The website serves webpages and REST API. The REST API connects to the
  ElasticSearch service in the first container.

- The *website development setup* is demonstrated by: running the ElasticSearch 
  in the container, but the website is running outside the container in the
  Python virtual environment. See the "Test web application outside container"
  section below.  

- The *local deployment of multi containers using the manual method* is
  demonstrated in the "Test application by starting each containers manually" 
  section below.

- The *local deployment using the docker compose method* is demonstrated in the
  "Test application by starting using docker compose" section below.

- Demonstrate the application *deployment to AWS ECS using the Fargate launch type*,
  a serverless approach, in the "Deploy" > "AWS ECS using docker compose v3" 
  section below. However, the deployment was not successful due to the limitation
  of Fargate and the ElasticSearch requirements. May need to revisit in the future. 
  See alternative approach below using AWS ECS EC2.

- Demonstrate the application *deployment to AWS ECS using the EC2 launch type*
  in the "Deploy" > "AWS ECS **Launch-type=EC2** using docker compose v2".
  Several parameters were also reconfigured from the above Fargate deployment.
  This deployment was succesful and demonstrated the multi-container application.

- **Future refinements of this demo** include:
  - Make the AWS ECS Fargate approach works for ElasticSearch as this is the 
    preferred AWS severless approach
  - This may be possible by using the "elasticsearch:7.6.2" container, 
    to overcome the
    `vm.max_map_count [65530] is too low, increase to at least [262144]` error,
    preventing the container to start, and
  - Using the docker-compose file version 3, and read the aws documentation
    on how to specify the followings in the `ecs-params.yml` file:
```
services:
[...]
    cpu_shares: 100
    mem_limit: 3621440000
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    logging:
      driver: awslogs
      options:
        awslogs-group: foodtrucks
        awslogs-region: us-west-2
        awslogs-stream-prefix: es
[...]
```    

## Prerequisite

- Docker Engine - see [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

- Docker Compose
```
$ sudo apt-get update
$ sudo apt-get install docker-compose
```

- ElasticSearch - we are using `docker.elastic.co/elasticsearch/elasticsearch:6.3.2`
  hosted by [Elastic.co](https://www.docker.elastic.co/r/elasticsearch), **not**
  the one from Docker Hub. Note: the latest version is `8.3.3` but the container
  encountered error during startup as shown in the "Issues to be investigated"
  section below.

- For deployment, **AWS account**;  see "Setup > AWS account"

- For deployment, **AWS CLI installed & configured**; 
  see "Setup > AWS CLI installed & Configured"
  
- For deployment, AWS ECS CLI installed; 
  see "Setup > AWS ECS CLI installed & configured"

## Setup

- Clone this repo

- The following tasks can be performed manually or by running the scripts
  included with this repo.

- To run the scripts, you need to make them executable first
```
$ cd <project_folder>/docker-compose-elasticsearch
$ chmod +x *.sh
```

- [Optional] To do it manually, copy the command inside the script file


Perform the following AWS setup prior to the "Deploy" section.

### AWS account

Go to [Amazon AWS](https://aws.amazon.com/) to create an account.

### AWS CLI installed & Configured

- Install AWS CLI - see [Getting started with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)

- Configure AWS CLI

- We assume that the AWS CLI has been configured as follow.

- The `default` profile has been created and stored in the `~/.aws/config` file
  as follow:
```
[default]
region=us-west-2
```

- The `default` credentials has been created and stored in the 
  `~/.aws/credential` file as follow:
```
[default]
aws_access_key_id = <replace_with_actual_id>
aws_secret_access_key = <replace_with_actual_secret>
```

### AWS ECS CLI installed & configured

- [Installing the Amazon ECS CLI](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html)

- [Configuring the Amazon ECS CLI](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_Configuration.html)
  We assume that the Amazon ECS CLI profile has been created with profile name
  of `ecs-tutorial`, and stored in the `~/.ecs/credentials` file, as follow:
```
version: v1
[...]
ecs_profiles:
  ecs-tutorial:
    aws_access_key_id: <replace_with_actual_id>
    aws_secret_access_key: <replace_with_actual_secret>
```

- We will configure the ECS CLI specifically for deploying this demo in this
  repo


## Develop

- Build the docker image for the "SFFoodtrucks" flask application
```
$ cd <project_folder>/docker-compose-elasticsearch
$ chmod +x build-image.sh
$ ./build-image.sh

$ docker images
REPOSITORY                         TAG                 IMAGE ID       CREATED          SIZE
gabepublic/sffoodtruck-site-flask  0.1.0-linux-amd64   07b791d8c0e8   24 minutes ago   501MB
ubuntu                             18.04               8d5df41c547b   8 days ago       63.1MB
```

- At this point, we can test the multi-container application, "sffoodtruck",
  manually as discussed below in 
  "Tests - Test application by starting each containers manually"

- Publish the docker image to Docker Hub. This step is mandatory before 
  deploying to AWS.  
```
$ $ docker login
#provide Docker Hub id and password
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

$ docker push gabepublic/sffoodtruck-site-flask:0.1.0-linux-amd64
[...]
0.1.0-linux-amd64: digest: sha256:e1301bcc996e0e975fa083eb79ab0d970018ea809b1bc76f0a10b10d2c98ae64 size: 1984

$ docker logout
```

- Check the `docker-compose.yml` file

- Next, test running the multi-container application, "sffoodtruck", using
  docker compose, as discussed below in 
  "Tests - Test application by starting using docker compose"
  
- Deploy the application to AWS; see "Deploy" section below.


## Tests

This application has two containers: the ElasticSearch service container, and
SFFoodTruck website container. The website serves the application webpage
and APIs that connects to the ElasticSearch service container. Therefore, 
the ElasticSearch container needs to be started first.

For this demo, the ElasticSearch docker image will be pulled from the official
repository hosted by `elastic.co`, and used without modification. The website
docker image is built using this repo, as defined in `Dockerfile`.
 
### Test web application outside container

The website can be revised and tested prior to rebuilding the docker image to
reduce development time, as follow:

- Start the ElasticSearch container
```
$ ./02-start-elasticcontainer-bridge-network.sh

# [Alternative]
$ docker run -d --name es -p 9200:9200 -p 9300:9300 \
                  -e "discovery.type=single-node" \
                  docker.elastic.co/elasticsearch/elasticsearch:6.3.2
```

- Check the container is running
```
$ docker logs es
```

- [Recommended] Create the Python virtual environment, activate the virtual
  environment, and install the required dependencies
```
$ cd <project_folder>/docker-compose-elasticsearch
$ virtualenv ./venv
$ source ./venv/bin/activate
(.venv) $ cd flaskapp
(.venv) $ pip install -r requirements.txt
```
  
- Modify the `<project_folder>/docker-compose-elasticsearch/flaskapp/app.py` 
  as shown below:
```
#es = Elasticsearch(host='es')
# Use the following when running outside thee container and connecting to
# ElasticSearch container
es = Elasticsearch()
```  
  
- Start the website
```
(.venv) $ cd <project_folder>/docker-compose-elasticsearch/flaskapp
(.venv) $ python ./app.py --commandline True
[...]
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://172.29.53.5:5000
Press CTRL+C to quit
```

- Open browser and go to:
  - `http://localhost:5000/`
  - `http://localhost:5000/debug`  
  - `http://localhost:5000/search?q=burger`  

- When all done, close the browser, and (CTRL+C) stops the website

- [Optional] Stop and delete the container
```
$ docker stop es
$ docker rm es
```

- [Optional] Delete the ElasticSearch docker image
```
$ docker image rm docker.elastic.co/elasticsearch/elasticsearch:6.3.2
```

### Test application by starting each containers manually

After building the website docker image, test the application by starting each
containers (i.e., ElasticSearch and website containers) individually, starting
with the ElasticSearch container.

However, before starting any containers we need to define a new network for
the containers to find and connect to each others, as explained in details
below.

- By default, docker containers run on the bridge network. Check the network:
```
# list the networks
$ docker network ls
NETWORK ID     NAME             DRIVER    SCOPE
7fb9c58ec5c5   bridge           bridge    local
e0ef2370704e   docker_default   bridge    local
3fd3dfe5c6a3   host             host      local
0b63a4acccd2   none             null      local

# show which containers are on the bridge network
$ docker network inspect bridge
```

- However, containers are not able to find nor connect to each other via the
  `0.0.0.0` or `localhost` because that is the port to access the container from
  the host only, not between containers. Therefore, we need to define a network,
  `foodtrucks-net`, where assigned containers can connect.
```
$ cd <project_folder>/docker-compose-elasticsearch/
$ ./03-create-custom-network.sh

# [Alternative]
$ docker network create foodtrucks-net
5c74154971d342e288401ed9880f3912304fcd98e3df8a9da4068db073b7cd4b

$ docker network ls
NETWORK ID     NAME             DRIVER    SCOPE
7fb9c58ec5c5   bridge           bridge    local
e0ef2370704e   docker_default   bridge    local
5c74154971d3   foodtrucks-net   bridge    local
3fd3dfe5c6a3   host             host      local
0b63a4acccd2   none             null      local
```

- Start the ElasticSearch container connecting the newly created network:
```
$ cd <project_folder>/docker-compose-elasticsearch/
$ ./04-start-elasticcontainer-custom-network.sh

# [Alternative]
$ docker run -d --name es --net foodtrucks-net 
                  -p 9200:9200 -p 9300:9300 \
                  -e "discovery.type=single-node" \
                  docker.elastic.co/elasticsearch/elasticsearch:6.3.2

$ docker ps
CONTAINER ID   IMAGE                                                 COMMAND                  CREATED         STATUS         PORTS
                                                                         NAMES
b1f352d90297   docker.elastic.co/elasticsearch/elasticsearch:6.3.2   "/usr/local/bin/dock…"   5 seconds ago   Up 3 seconds   0.0.0.0:9200->9200/tcp, :::9200->9200/tcp, 0.0.0.0:9300->9300/tcp, :::9300->9300/tcp   es
```

- Check the ElasticSearch container is running
```
$ docker logs es
[...]
[2022-08-11T03:17:32,339][INFO ][o.e.c.m.MetaDataIndexTemplateService] [9Hp2zTE] adding template [.monitoring-kibana] for index patterns [.monitoring-kibana-6-*]
[2022-08-11T03:17:32,505][INFO ][o.e.l.LicenseService     ] [9Hp2zTE] license [bbd4078b-be07-4fef-ad01-d5eca5cf4b6d] mode [basic] - valid
```

- Check the container is running on the `foodtrucks-net` network
```
$ docker network inspect foodtrucks-net
[
    {
        "Name": "foodtrucks-net",
        "Id": "5c74154971d342e288401ed9880f3912304fcd98e3df8a9da4068db073b7cd4b",
        "Created": "2022-08-10T20:13:21.4511024-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "172.19.0.0/16",
                    "Gateway": "172.19.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "b1f352d902973c1ae03ff8caae87de23cc3376d6621f27fcf07217838871f6de": {
                "Name": "es",
                "EndpointID": "697be69f541c349fae252370771a33db7b7dc75e9119f4d4ac187691d71e03cc",
                "MacAddress": "02:42:ac:13:00:02",
                "IPv4Address": "172.19.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
```

- Start the website container also connecting the newly created network:
```
$ cd <project_folder>/docker-compose-elasticsearch
$ ./05-start-flaskcontainer.sh

# [Alternative]
$ docker run -d --name foodtrucks-web --net foodtrucks-net -p 5000:5000 gabepublic/sffoodtruck-site-flask:0.1.0-linux-amd64
```

- Check the website container is running
```
$ docker logs foodtrucks-web
[...]
 * Running on http://172.19.0.3:5000/ (Press CTRL+C to quit)
```

- Open browser and go to:
  - `http://localhost:5000/`
  - `http://localhost:5000/debug`  
  - `http://localhost:5000/search?q=burger`  

- When all done, close the browser, and stop the containers and delete the
  network
```
$ ./06-stop-containers.sh
```

### Test application by starting using docker compose
  
- Start the multi-container application using docker compose
```
$ cd <project_folder>/docker-compose-elasticsearch
$ docker-compose up -d
```

- Check the custom network has been created, and inspect the network that both 
  containers are connect to it.
```
$ docker network ls
NETWORK ID     NAME                                   DRIVER    SCOPE
7fb9c58ec5c5   bridge                                 bridge    local
b3cf8573b6e8   docker-compose-elasticsearch_default   bridge    local
e0ef2370704e   docker_default                         bridge    local
3fd3dfe5c6a3   host                                   host      local
0b63a4acccd2   none                                   null      local

$ docker inspect docker-compose-elasticsearch_default
[
    {
        "Name": "docker-compose-elasticsearch_default",
        "Id": "b3cf8573b6e8e92726db439df49e77b3d2715576f4f2df4b40facd4b45fd4444",
        "Created": "2022-08-11T15:38:39.0960527-07:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.24.0.0/16",
                    "Gateway": "172.24.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": true,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "758451732cc697c6c831116a97db0eab64808b3a15398c101545cfbc61ab6445": {
                "Name": "docker-compose-elasticsearch_web_1",
                "EndpointID": "51dfbe46c5566066f6282c15e93376c81e32b9bdbd43138b9354b6bebe8c2a1d",
                "MacAddress": "02:42:ac:18:00:03",
                "IPv4Address": "172.24.0.3/16",
                "IPv6Address": ""
            },
            "b6d5c40c4188ad1c53681e3401c75b4dbe30829deba9587f93fccbf11d396f70": {
                "Name": "es",
                "EndpointID": "c52b69089ae25700af27201d7a0cbfecbf727ce3bdbee5c9ab020ecc929eb22b",
                "MacAddress": "02:42:ac:18:00:02",
                "IPv4Address": "172.24.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {
            "com.docker.compose.network": "default",
            "com.docker.compose.project": "docker-compose-elasticsearch",
            "com.docker.compose.version": "1.25.0"
        }
    }
]
```

- Check two containers are running
```
$ docker ps
CONTAINER ID   IMAGE                                                 COMMAND                  CREATED         STATUS         PORTS
                                        NAMES
758451732cc6   gabepublic/sffoodtruck-site-flask:0.1.0-linux-amd64   "python3 app.py"         3 minutes ago   Up 2 minutes   0.0.0.0:5000->5000/tcp, :::5000->5000/tcp             docker-compose-elasticsearch_web_1
b6d5c40c4188   docker.elastic.co/elasticsearch/elasticsearch:6.3.2   "/usr/local/bin/dock…"   3 minutes ago   Up 3 minutes   0.0.0.0:9200->9200/tcp, :::9200->9200/tcp, 9300/tcp   es
```

- Check ElasticSearch log
```
$ docker logs es
[...]
[2022-08-11T22:38:56,014][WARN ][o.e.x.s.a.s.m.NativeRoleMappingStore] [vXa0esb] Failed to clear cache for realms [[]]
[2022-08-11T22:38:56,054][INFO ][o.e.l.LicenseService     ] [vXa0esb] license [e574e19d-62dc-460c-a421-cb28210106f1] mode [basic] - valid
[2022-08-11T22:38:56,074][INFO ][o.e.g.GatewayService     ] [vXa0esb] recovered [1] indices into cluster_state
[2022-08-11T22:38:57,112][INFO ][o.e.c.r.a.AllocationService] [vXa0esb] Cluster health status changed from [RED] to [YELLOW] (reason: [shards started [[sfdata][2]] ...]).
```

- Check website logs
```
$ docker logs docker-compose-elasticsearch_web_1
 * Serving Flask app 'app' (lazy loading)
 * Environment: production
   WARNING: This is a development server. Do not use it in a production deployment.
   Use a production WSGI server instead.
 * Debug mode: on
 * Running on all addresses.
   WARNING: This is a development server. Do not use it in a production deployment.
 * Running on http://172.24.0.3:5000/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 923-816-411
```

- Open browser and go to:
  - `http://localhost:5000/`
  - `http://localhost:5000/debug`  
  - `http://localhost:5000/search?q=burger`  

- When all done, close the browser, and stop & delete the application using
  `docker-compose`:
```
$ docker-compose down -v
Stopping docker-compose-elasticsearch_web_1 ... done
Stopping es                                 ... done
Removing docker-compose-elasticsearch_web_1 ... done
Removing es                                 ... done
Removing network docker-compose-elasticsearch_default
Removing volume docker-compose-elasticsearch_esdata1
```


## Deploy

### AWS ECS using docker compose v3

**WARNING:** the following deployment to AWS ECS had some issues; the deployment
was successful BUT the ElasticSearch container failed to start due to the
following error; and hence the website container also exited by design and 
the container stopped.
```
ERROR: [3] bootstrap checks failed
[1]: max file descriptors [4096] for elasticsearch process is too low, increase to at least [65535]
[2]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
[3]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
```

This error is a known issue with the ECS with Fargate (serverless) deployment,
and but it seems to be a very low priority (or not to fix) by aws.
The issue was reported:
- https://stackoverflow.com/questions/62860516/how-to-increase-the-vm-max-map-count-in-aws-ecs-fargate
- https://medium.com/@devfire/deploying-the-elk-stack-on-amazon-ecs-part-2-34c841e3b774

This error did not happen on the local deployment as shown above:
- "Test application by starting each container manually"
- "Test application by starting using docker compose"

Further due dilligence is needed to resolve the issue.

**NOTE:** the error did not occur when using the "ECS -> EC2", self-managed
deployment, and using the docker compose v2, and ElasticSearch version 7.6.2,
as demonstrated by 
[Docker Curriculum - MULTI-CONTAINER ENVIRONMENTS](https://docker-curriculum.com/#multi-container-environments)
and reproduced below in "AWS ECS **Launch-type=EC2** using docker compose v2".

**Step-by-step:**

- Check `ecs-cli`
```
$ ecs-cli --version
ecs-cli version 1.21.0 (bb0b8f0)
```

- Make sure the AWS prerequisites (see "Prerequisites" section above) have been
  fulfilled, and "ecs_profiles > ecs-tutorial" exists.

- Make sure the website docker image has been published to Docker Hub,
  See "Develop" section above for instructions.

- For more detailed information about the following steps, please refer to
  [aws-ecs-docker-php-01](https://github.com/gabepublic/aws-ecs-docker-php-01)

- Change the directory
```
$ cd <project_folder>/docker-compose-elasticsearch/deploy-aws
```

- Create the task execution IAM role and attach policy:
```
$ ./01_create_task_execution_role_policy.sh
Creating ecsTaskExecutionRole in us-west-2
{
    "Role": {
        "Path": "/",
        "RoleName": "ecsTaskExecutionRole",
        "RoleId": "AROAVCVML3GI3PA5P7ULU",
        "Arn": "arn:aws:iam::349327579537:role/ecsTaskExecutionRole",
        "CreateDate": "2022-08-12T02:46:49+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "ecs-tasks.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}
Add to ecsTaskExecutionRole, policy AmazonECSTaskExecutionRolePolicy, in us-west-2
```

- Create ecs-cli cluster config
```
$ ./03_create_aws_ecs_cluster_config.sh
Create cluster ecs-cluster-sffoodtrucks, config ecs-tutorial, launch type FARGATE in us-west-2
INFO[0000] Saved ECS CLI cluster configuration ecs-tutorial.
Create AWS cloud cluster based on cli config ecs-tutorial and profile ecs-tutorial ...
INFO[0000] Created cluster                               cluster=ecs-cluster-sffoodtrucks region=us-west-2
INFO[0001] Waiting for your cluster resources to be created...
INFO[0001] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
VPC created: vpc-092fccfdeb5001f83
Subnet created: subnet-0c23aab29537bd147
Subnet created: subnet-0e841e329417e2f98
Cluster creation succeeded.
Capture the VPC_ID and continue on the next step...
```

- Capture the `VPC_ID` from the above step, and add the Security Group Rule.
  The script will ask the `VPC_ID`.
```
$ ./05_retrieve_vpc_secinfo.sh
Enter the VPC_ID (vpc-***)?
vpc-092fccfdeb5001f83
retrieve the Security GroupId for vpc-092fccfdeb5001f83
{
    "SecurityGroups": [
        {
            "Description": "default VPC security group",
            "GroupName": "default",
            "IpPermissions": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": [
                        {
                            "GroupId": "sg-04e2e3b909c8d787c",
                            "UserId": "349327579537"
                        }
                    ]
                }
            ],
            "OwnerId": "349327579537",
            "GroupId": "sg-04e2e3b909c8d787c",
            "IpPermissionsEgress": [
                {
                    "IpProtocol": "-1",
                    "IpRanges": [
                        {
                            "CidrIp": "0.0.0.0/0"
                        }
                    ],
                    "Ipv6Ranges": [],
                    "PrefixListIds": [],
                    "UserIdGroupPairs": []
                }
            ],
            "VpcId": "vpc-092fccfdeb5001f83"
        }
    ]
}
Capture the VPC Security GroupId and continue on the next step...
```

- Capture the VPC Security GroupId, and add security group rule to allow 
  inbound access on port 5000. The script will ask the `Security GroupId`.
  NOTE: port 5000 is used because for networkMode=awsvpc, the host ports and 
  container ports in port mappings must match.
```
$ ./06_create_aws_ecs_cluster_create_secrule.sh
Enter the Security Group - GroupId (sg-***)?
sg-04e2e3b909c8d787c
add a security group rule to allow inbound access on port 5000
{
    "Return": true,
    "SecurityGroupRules": [
        {
            "SecurityGroupRuleId": "sgr-0de0d1aec9033757a",
            "GroupId": "sg-04e2e3b909c8d787c",
            "GroupOwnerId": "349327579537",
            "IsEgress": false,
            "IpProtocol": "tcp",
            "FromPort": 5000,
            "ToPort": 5000,
            "CidrIpv4": "0.0.0.0/0"
        }
    ]
}
```

- Deploy AWS ECS cluster; two files are needed: `docker-compose.yml` and
  `ecs-params.yml`. **Revise** the `ecs-params.yml` to use the actual
  VPC, subnet, and security group IDs from the previous step.
```
$ ./07_create_aws_ecs_cluster_deploy_list.sh
deploying cluster sffoodtrucks...
INFO[0000] Using ECS task definition                     TaskDefinition="sffoodtrucks:3"
INFO[0000] Created Log Group foodtrucks in us-west-2
WARN[0000] Failed to create log group foodtrucks in us-west-2: The specified log group already exists
INFO[0000] Auto-enabling ECS Managed Tags
INFO[0011] (service sffoodtrucks) has started 1 tasks: (task ef283d57e72940fb817b37beecacd011).  timestamp="2022-08-12 05:42:35 +0000 UTC"
INFO[0052] Service status                                desiredCount=1 runningCount=1 serviceName=sffoodtrucks
INFO[0052] ECS Service has reached a stable state        desiredCount=1 runningCount=1 serviceName=sffoodtrucks
INFO[0052] Created an ECS service                        service=sffoodtrucks taskDefinition="sffoodtrucks:3"
```

- View the Running Containers on a Cluster
```
$ ./08_view_running_containers.sh
Name                                                           State    Ports                        TaskDefinition  Health
ecs-cluster-sffoodtrucks/ef283d57e72940fb817b37beecacd011/web  RUNNING  54.201.54.11:5000->5000/tcp  sffoodtrucks:3  UNKNOWN
ecs-cluster-sffoodtrucks/ef283d57e72940fb817b37beecacd011/es   RUNNING  54.201.54.11:9200->9200/tcp  sffoodtrucks:3  UNKNOWN
```

- View the Container Logs using the `TASK_ID` value for the container, shown 
  above. Revise the script with the actual `TASK_ID`.
```
$ ./09_view_container_logs.sh
```

- Scale the Tasks (number of containers) on the Cluster
```
$ ./10_scale_up_numberof_containers.sh
```
  - Verify the number of clusters
```
$ ./08_view_running_containers.sh
```

- View the application from the URL:
  - `http://34.208.74.12:80/`


#### CLEANUP

- Delete the service so that it stops the existing containers and does not try 
  to run any more tasks. Then take down your cluster, which cleans up the 
  resources that you created earlier with ecs-cli up. Both tasks have been
  included in the `11_cleanup_aws_ecs_cluster.sh` script:
```
$ ./11_cleanup_aws_ecs_cluster.sh
```

- Delete task definitions, `ecs-tutorial`, from the AWS console; go to
  "Amazon Elastic Container Service > Task Definitions" page.
  - Click the task definitions `ecs-tutorial`
  - On the `ecs-tutorial` task definitions page, select the `ecs-tutorial`
    Task definition: revision, then "Deregister"

- Delete the CloudWatch log group, `foodtrucks`, from the AWS Console, go to
  "CloudWatch > Log groups"

- Delete the role name `ecsTaskExecutionRole` (if no longer needed);
  use the "AWS console > IAM > Access Management > Roles"
  
- Delete the AWS ECS profile `ecs-sffoodtrucks` (if no longer needed) from the local
  `~/.ecs/config` file:
```
version: v1
[...]
clusters:
  ecs-sffoodtrucks:
    cluster: ecs-sffoodtrucks
    region: us-west-2
    default_launch_type: FARGATE
[...]
```

### AWS ECS **Launch-type=EC2** using docker compose v2

Summary:
- AWS ECS Launch-type=EC2 using t2.medium
- docker compose v2 and configure the mem_limit (in bytes) and cpu_shares values
- docker.elastic.co/elasticsearch/elasticsearch:7.6.2

**Step-by-step deployment:**

The following setup tasks can be perfomed manually or by running the scripts
included with this repo.

- Change directory
```
$ cd <project_folder>/docker-compose-elasticsearch/deploy-aws-v2
```

- Ensure the following prerequisites are ready: AWS account; AWS CLI installed &
  Configured; and AWS ECS CLI installed & profile configured.

- If not already, configure the Amazon ECS CLI cluster for deploying this demo:
  - As indicated above, we assume the ECS profile, `ecs-tutorial`, has been 
    configured and the `~/.ecs/credentials` file, has the following:
```
version: v1
[...]
ecs_profiles:
  ecs-tutorial:
    aws_access_key_id: <replace_with_actual_id>
    aws_secret_access_key: <replace_with_actual_secret>
```  
  - Create a ECS CLI cluster configuration, which defines the AWS region to use, 
    resource creation prefixes, and the cluster name to use with the Amazon ECS 
    CLI; using the `03_create_aws_ecs_cluster_config.sh`:
```
$ cd <project_folder>\aws-ecs-docker-php-01\deploy-aws-v2
$ ./03_create_aws_ecs_cluster_config.sh
Create a cluster ecs-ec2-tutorial, config ecs-ec2-tutorial, launch type EC2 in us-west-2
INFO[0000] Saved ECS CLI cluster configuration ecs-ec2-tutorial.
```
  - Verify the local `~/.ecs/config` file contains the following:
```
version: v1
[...]
clusters:
  ecs-ec2-tutorial:
    cluster: ecs-ec2-tutorial
    region: us-west-2
    default_launch_type: EC2
[...]
```

- Setup cluster
```
$ cd <project_folder>\aws-ecs-docker-php-01\deploy-aws-v2
$ ./04_create_aws_ecs_cluster_create.sh
Enter the SSH RSA key-pair?
<replace-with-real-keypair>
Create aws cloud cluster based on cli config and profile...
INFO[0001] Using recommended Amazon Linux 2 AMI with ECS Agent 1.61.3 and Docker version 20.10.13
INFO[0001] Created cluster                               cluster=ecs-ec2-tutorial region=us-west-2
INFO[0001] Waiting for your cluster resources to be created...
INFO[0001] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
INFO[0062] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
INFO[0123] Cloudformation stack status                   stackStatus=CREATE_IN_PROGRESS
VPC created: vpc-009636f1d0c0ad22b
Security Group created: sg-0de3daafac2a77878
Subnet created: subnet-0cda23b43024c34d2
Subnet created: subnet-0831d526126a8f3bf
Cluster creation succeeded.
```

- Deploy
```
$ cd <project_folder>\aws-ecs-docker-php-01\deploy-aws-v2
$ ./07_create_aws_ecs_cluster_deploy.sh
deploy the cluster
INFO[0000] Using ECS task definition                     TaskDefinition="deploy-aws-v2:2"
INFO[0000] Created Log Group foodtrucks in us-west-2
WARN[0000] Failed to create log group foodtrucks in us-west-2: The specified log group already exists
INFO[0000] Auto-enabling ECS Managed Tags
INFO[0001] Starting container...                         container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es
INFO[0001] Starting container...                         container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web
INFO[0001] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=RUNNING lastStatus=PENDING
 taskDefinition="deploy-aws-v2:2"
INFO[0001] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=RUNNING lastStatus=PENDING taskDefinition="deploy-aws-v2:2"
INFO[0013] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=RUNNING lastStatus=PENDING
 taskDefinition="deploy-aws-v2:2"
INFO[0013] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=RUNNING lastStatus=PENDING taskDefinition="deploy-aws-v2:2"
INFO[0026] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=RUNNING lastStatus=PENDING
 taskDefinition="deploy-aws-v2:2"
INFO[0026] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=RUNNING lastStatus=PENDING taskDefinition="deploy-aws-v2:2"
INFO[0038] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=RUNNING lastStatus=PENDING
 taskDefinition="deploy-aws-v2:2"
INFO[0038] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=RUNNING lastStatus=PENDING taskDefinition="deploy-aws-v2:2"
INFO[0050] Started container...                          container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=RUNNING lastStatus=RUNNING
 taskDefinition="deploy-aws-v2:2"
INFO[0050] Started container...                          container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=RUNNING lastStatus=RUNNING taskDefinition="deploy-aws-v2:2"
```

- Check containers
```
$ cd <project_folder>\aws-ecs-docker-php-01\deploy-aws-v2
$ ./08_view_running_containers.sh
Name                                                   State    Ports                      TaskDefinition   Health
ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web  RUNNING  35.92.75.208:80->5000/tcp  deploy-aws-v2:2  UNKNOWN
ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es   RUNNING
```

- Cleanup, as discussed below


#### CLEANUP

- Delete the service so that it stops the existing containers and does not try 
  to run any more tasks. Then take down your cluster, which cleans up the 
  resources that you created earlier with ecs-cli up. Both tasks have been
  included in the `11_cleanup_aws_ecs_cluster.sh` script:
```
$ cd <project_folder>\aws-ecs-docker-php-01\deploy-aws-v2
$ ./11_cleanup_aws_ecs_cluster.sh
INFO[0000] Stopping container...                         container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web
INFO[0000] Stopping container...                         container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es
INFO[0000] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=STOPPED lastStatus=RUNNING
 taskDefinition="deploy-aws-v2:2"
INFO[0000] Describe ECS container status                 container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=STOPPED lastStatus=RUNNING taskDefinition="deploy-aws-v2:2"
INFO[0006] Stopped container...                          container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/web desiredStatus=STOPPED lastStatus=STOPPED
 taskDefinition="deploy-aws-v2:2"
INFO[0006] Stopped container...                          container=ecs-ec2-tutorial/43e0907cddc847c2a5ab475ab5a3fd8c/es desiredStatus=STOPPED lastStatus=STOPPED taskDefinition="deploy-aws-v2:2"
INFO[0000] Waiting for your cluster resources to be deleted...
INFO[0000] Cloudformation stack status                   stackStatus=DELETE_IN_PROGRESS
INFO[0061] Cloudformation stack status                   stackStatus=DELETE_IN_PROGRESS
INFO[0122] Cloudformation stack status                   stackStatus=DELETE_IN_PROGRESS
INFO[0183] Cloudformation stack status                   stackStatus=DELETE_IN_PROGRESS
INFO[0214] Deleted cluster                               cluster=ecs-ec2-tutorial
```

- Delete task definitions, `deploy-aws-v2`, from the AWS console; go to
  "Amazon Elastic Container Service > Task Definitions" page.
  - Click the task definitions `deploy-aws-v2`
  - On the `deploy-aws-v2` task definitions page, select the `deploy-aws-v2:2`
    Task definition: revision, then "Deregister". That will delete the
    `deploy-aws-v2` task
  - Note: the name, `deploy-aws-v2`, was taken from the folder name where the
    `docker-compose.yml` file resided.  

- Delete the CloudWatch log group, `foodtrucks`, from the AWS Console, go to
  "CloudWatch > Log groups"

- Delete the role name `ecsTaskExecutionRole` (if no longer needed);
  use the "AWS console > IAM > Access Management > Roles"
  
- Delete the AWS ECS profile `ecs-ec2-sffoodtrucks` (if no longer needed) from the local
  `~/.ecs/config` file:
```
version: v1
[...]
clusters:
  ecs-ec2-sffoodtrucks:
    cluster: ecs-ec2-sffoodtrucks
    region: us-west-2
    default_launch_type: FARGATE
[...]
```

- The EC2 instance should have been terminated as well. It will still show on
  the "EC2 > Instances" for a while but should disappear eventually.

## Issues to be investigated

- [Resolved] Error during startup of `docker.elastic.co/elasticsearch/elasticsearch:8.3.3`
```
org.elasticsearch.ElasticsearchSecurityException: invalid configuration for xpack.security.transport.ssl - [xpack.security.transport.ssl.enabled] is not set, but the following settings have been configured in elasticsearch.yml : [xpack.security.transport.ssl.keystore.secure_password,xpack.security.transport.ssl.truststore.secure_password]
        at org.elasticsearch.xcore@8.3.3/org.elasticsearch.xpack.core.ssl.SSLService.validateServerConfiguration(SSLService.java:648)
        at org.elasticsearch.xcore@8.3.3/org.elasticsearch.xpack.core.ssl.SSLService.loadSslConfigurations(SSLService.java:612)
        at org.elasticsearch.xcore@8.3.3/org.elasticsearch.xpack.core.ssl.SSLService.<init>(SSLService.java:156)
        at org.elasticsearch.xcore@8.3.3/org.elasticsearch.xpack.core.XPackPlugin.createSSLService(XPackPlugin.java:461)
        at org.elasticsearch.xcore@8.3.3/org.elasticsearch.xpack.core.XPackPlugin.createComponents(XPackPlugin.java:310)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.node.Node.lambda$new$14(Node.java:668)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.plugins.PluginsService.lambda$flatMap$0(PluginsService.java:235)
        at java.base/java.util.stream.ReferencePipeline$7$1.accept(ReferencePipeline.java:273)
        at java.base/java.util.stream.ReferencePipeline$3$1.accept(ReferencePipeline.java:197)
        at java.base/java.util.AbstractList$RandomAccessSpliterator.forEachRemaining(AbstractList.java:720)
        at java.base/java.util.stream.AbstractPipeline.copyInto(AbstractPipeline.java:509)
        at java.base/java.util.stream.AbstractPipeline.wrapAndCopyInto(AbstractPipeline.java:499)
        at java.base/java.util.stream.AbstractPipeline.evaluate(AbstractPipeline.java:575)
        at java.base/java.util.stream.AbstractPipeline.evaluateToArrayNode(AbstractPipeline.java:260)
        at java.base/java.util.stream.ReferencePipeline.toArray(ReferencePipeline.java:616)
        at java.base/java.util.stream.ReferencePipeline.toArray(ReferencePipeline.java:622)
        at java.base/java.util.stream.ReferencePipeline.toList(ReferencePipeline.java:627)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.node.Node.<init>(Node.java:681)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.node.Node.<init>(Node.java:300)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.bootstrap.Bootstrap$5.<init>(Bootstrap.java:230)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:230)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:333)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:224)
        at org.elasticsearch.server@8.3.3/org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:67)
For complete error details, refer to the log at /usr/share/elasticsearch/logs/elasticsearch.log
ERROR: Elasticsearch did not exit normally - check the logs at /usr/share/elasticsearch/logs/elasticsearch.log

ERROR: Elasticsearch exited unexpectedly
```

- This error is a known issue with the ECS with Fargate (serverless) deployment,
and but it seems to be a very low priority (or not to fix) by aws.
The issue was reported:
- https://stackoverflow.com/questions/62860516/how-to-increase-the-vm-max-map-count-in-aws-ecs-fargate
- https://medium.com/@devfire/deploying-the-elk-stack-on-amazon-ecs-part-2-34c841e3b774


## Refereces

- [Docker Curriculum - MULTI-CONTAINER ENVIRONMENTS](https://docker-curriculum.com/#multi-container-environments)

- [Deploying the ELK stack on AWS ECS, Part 1: Introduction & First Steps](https://medium.com/@devfire/deploying-the-elk-stack-on-amazon-ecs-dd97d671df06)