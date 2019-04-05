# Data Wrangling with Nifi, Spark and MongoDB
This tutorial will take you through the following steps to build a real time streaming application for analysis of Twitter Data. The brand to perform analysis for is Nike. Nike is one of the most famous corporations that can be found on the planet. In significant part, this is because of its outstanding marketing, which has made it a household name in countries situated all around the globe.

**Environment:**
Windows 10 Home  
16 GB RAM  
Docker ToolBox v 18.03.0-ce  
Git Bash  
HDP 2.6.5 Sandbox  
HDF 3.1.1 Sandbox  

**A quick twitter search for #Nike, #ChooseGo helps us shortlist some keywords that we can use for Twitter Search API.**  
Nike  
Swoosh  
JustDoIt  
AirMax  
NikeAdapt  
NikeAir  
Nike+  
Nikbasketball  
NikeRunning  
NikeTraining  
NikePlus  
ChooseGo  
NikeSportsWear  


## Steps in this tutorial:
1. [Sandbox Installation](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#sandbox-installation)
2. [Create Twitter API Application](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#create-twitter-application)
3. [Setup Development Environment](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#setup-development-environment)
4. [Create Nifi DataFlow for tweets ingestion into Kafka](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#nifi-dataflow)
5. Build SparkSQL Application for data cleaning
6. Build sentiment analysis model using gradient boosting
7. Build spark streaming application to store sentiment score in kafka topic
8. Perform Analysis in MongoDB

# Sandbox Installation
## Setup HDP Sandbox

**Prerequisites:**
1. Install Docker
2. HDP Sandbox requires minimum 10GB allocated to the virtual machine
3. Allocate maximum size to disk space to pull large images

The complete deployment script for HDP sandbox is available [here](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/tree/master/hdp_deploy)

In order to store streaming data, perform real time analytics and artifical intelligence etc. we need to utilize the capabilites of both HDP and HDF to achieve our goal. For this type of data architecure, hybrid is an essential requirement. While HDP stores, processes, and analyzes large volumes of data, data flow and management is delievered through HDF's NiFi. **Connected Data Architecture** is currently supported by HDP 2.6.5 and HDF version 3.1.1. Hortonworks Connected Data Architecture (CDA) is composed of both Hortonworks DataFlow (HDF) and Hortonworks DataPlatform (HDP) sandboxes and allows you to play with both data-in-motion and data-at-rest frameworks simultaneously.

**Executing HDP Deployment Script in Docker**  
Install [Git Bash](https://gitforwindows.org/) for Windows  
Clone or download the repository in the Downloads folder  
Open hdp-deploy folder  
Right click to start Git-Bash in this folder.  
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/Execute%20script.png)

Execute the docker-deploy-hdpXX.sh script
```
sh docker-deploy-hdpXX.sh
```  
The script execution should look something like this
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/hdp-deploy.JPG)

## Setup HDF Sandbox
Similar to HDP deployment, execute Downloads->hdf_deploy->docker-deploy-hdf311.sh
```
sh docker-deploy-hdfXXX.sh
```
The script execution should look something like this
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/hdf_deploy.JPG)

After the installation of HDP and HDF , enable CDA by executing the enable-native-cda script in this folder.
```
sh enable-native-cda.sh
```

## Installation Checks

Now that both HDP and HDF sandbox have been deployed, you can see the containers running in docker as follows:
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/SandboxContainers.png)

The first is the NGINX proxy container followed by HDF and HDP containers.
**NGINX Proxy** is  a reverse proxy server that resides behind a firewall and directs incoming requests to multiple backend servers. In our case, it is HDP and HDF containers.

## Map Sandbox IP to hostname
We will now map the ip address of the docker machine with that of the hostname. Remember, the Nginx reverse proxy server directs the request to the appropriate container. Here, based on the hostname, appropriate sandbox conatiner will be accessed.

```
#IP Address of the docker machine
$ docker-machine ip
XXX.XXX.XX.XXX
```
1. Run Notepad as administrator.   
2. Open hosts file located in: c:\Windows\System32\drivers\etc\hosts  
3. Add {IP-Address} localhost sandbox-hdp.hortonworks.com sandbox-hdf.hortonworks.com   
4. Save the file  
**IMPORTANT**: Replace {IP-Address} with Sandbox IP Address  

**HDP and HDF Sandbox are now setup**  
HDP Sandbox:  http://sandbox-hdp.hortonworks.com:8080  
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/hdp-Ambari.JPG)
HDF Sandbox:  http://sandbox-hdf.hortonworks.com:8080  
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/HDF-Ambari.JPG)



[Login Credentials](https://hortonworks.com/tutorial/learning-the-ropes-of-the-hortonworks-sandbox/#login-credentials)

# Create Twitter Application

Twitter's developer [portal](https://developer.twitter.com) includes numerious API endpoints and tools that helps you build an app on T
Twitter.

Visit the developer portal with an approved developer account to create a Twitter App and generate your authentication tokens. These include 'consumer' tokens and secrets for app authentication, and 'access' tokens and secrets for user/account authentication. 

Click on 'Create an App'.  
Fill in required fields:
1. App Name
2. Application Description
3. Website URL
4. Tell us how this app will be used
Click on 'Create'

Following is an example of required fields to be filled:
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/TwitterApplication.JPG)

You can now access your authentication tokens
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/TwitterAuthenticationtokens.png)

We will use this to fetch and store Twitter data in kafka topic at a later stage.

# Setup Development Envrionment

Verify Prerequisites before setting up development environmet:
1. Map hostname with Sandbox IP
2. Setup Ambari Admin password for HDP and HDF
3. Acquire Twitter authorization tokens

## Setup HDF Development Environemnt
The first step will be to start 'Nifi' in Ambari as we will need it to develop data flow for acquiring twitter data.

The Twitter API stores and returns tweets in GMT. It is important to syncronize the system clock with GMT to avoid running into authorization errors while connecting to the Twitter API Feed through GetTwitter processor. Another reason to syncronize the clocks is that since we will collect the tweets in batches at an interval of few seconds, we may loose some tweets that may have appeared since the last updated time.  
```
$ docker exec -it sandbox-hdf bin/bash
[root@sandbox-hdf /]#  echo "Synchronizing CentOS7 System Clock with UTC for GetTwitter Processor"
[root@sandbox-hdf /]# # Install Network Time Protocol
[root@sandbox-hdf /]# yum install -y ntp
[root@sandbox-hdf /]# service ntpd stop
[root@sandbox-hdf /]# # Use the NTPDATE to synchronize CentOS7 sysclock within few ms of UTC
[root@sandbox-hdf /]# ntpdate pool.ntp.org
[root@sandbox-hdf /]# service ntpd start
```

The second part of the code cleans up the NiFi flow that is already prebuilt into HDF Sandbox by backing up the flow and removing it.
```
mv /var/lib/nifi/conf/flow.xml.gz /var/lib/nifi/conf/flow.xml.gz.bak
```
Restart **Nifi** from Ambari UI for the changes to take effect.
If Kafka is off, make sure to turn it on from Ambari.

We will need to create a **Kafka** topic on HDF for Spark to stream data into from HDP.
```
/usr/hdf/current/kafka-broker/bin/kafka-topics.sh --create --zookeeper sandbox-hdf.hortonworks.com:2181 --replication-factor 1 --partitions 10 --topic tweetsSentiment
exit
```


## Setup HDP Development environment
Ensure that kafka, HDFS and Spark  are running in HDP Ambari. If not, restart all services for these components.
```
docker exec -it sandbox-hdp bin/bash
```  

**Setup Kafka Service**  
Create a Kafka topic on HDP for NiFi to publish messages to the Kafka queue.  
```
/usr/hdp/current/kafka-broker/bin/kafka-topics.sh --create --zookeeper sandbox-hdp.hortonworks.com:2181 --replication-factor 1 --partitions 10 --topic tweets
```


 **Setup HDFS Service**
 We will now create tweets folder that will hold a zipped file. This data will be copied over to HDFS where it will be later loaded by Spark to refine the historical data for creating a machine learning model. 
 ```
 echo "Setting up HDFS for Tweet Data"
HDFS_TWEET_STAGING="/sandbox/tutorial-files/770/tweets_staging"
LFS_TWEETS_PACKAGED_PATH="/sandbox/tutorial-files/770/tweets"
sudo -u hdfs mkdir -p $LFS_TWEETS_PACKAGED_PATH
# Create tweets_staging hdfs directory ahead of time for hive
sudo -u hdfs hdfs dfs -mkdir -p $HDFS_TWEET_STAGING
# Change HDFS ownership of tweets_staging dir to maria_dev
sudo -u hdfs hdfs dfs -chown -R maria_dev $HDFS_TWEET_STAGING
# Change HDFS tweets_staging dir permissions to everyone
sudo -u hdfs hdfs dfs -chmod -R 777 $HDFS_TWEET_STAGING
# give anyone rwe permissions to /sandbox/tutorial-files/770
sudo -u hdfs hdfs dfs -chmod -R 777 /sandbox/tutorial-files/770
sudo -u hdfs wget https://github.com/hortonworks/data-tutorials/raw/master/tutorials/cda/building-a-sentiment-analysis-application/application/setup/data/tweets.zip -O $LFS_TWEETS_PACKAGED_PATH/tweets.zip
sudo -u hdfs unzip $LFS_TWEETS_PACKAGED_PATH/tweets.zip -d $LFS_TWEETS_PACKAGED_PATH
sudo -u hdfs rm -rf $LFS_TWEETS_PACKAGED_PATH/tweets.zip
# Remove existing (if any) copy of data from HDFS. You could do this with Ambari file view.
sudo -u hdfs hdfs dfs -rm -r -f $HDFS_TWEET_STAGING/* -skipTrash
# Move downloaded JSON file from local storage to HDFS
sudo -u hdfs hdfs dfs -put $LFS_TWEETS_PACKAGED_PATH/* $HDFS_TWEET_STAGING
```
**Setup Spark Service**
For Spark Structured Streaming, we will need to leverage SBT package manager. The commands below install SBT. 

```
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
yum install -y sbt
```

# NIFI Dataflow

We will build two dataflows to perform two separate functions
**DataFlow1:** This NiFi dataflow will ingest data from Twitter using the twitter credentials, pull key attributes that will help with our analysis and store the data in Kafka topic called tweets  
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/DataFlow1.png)

**DataFlow2:** The second NiFi flow in another process group will consume data from Kafka topic  ‘tweetsSentiment’, which has a trained sentiment model built with an external service SparkML and send the data to be stored into MongoDB.   

It is recommended to import the NiFi flow from your local computer to the NiFi Interface.   

1.	Open the Nifi Interface: http://sandbox-hdf.hortonworks.com:9090/nifi/  
2.	Right Click to select ‘Upload Template’  
3.	Click on the search icon and select the XML file  
4.	Click on the Upload Button  

## Deep Dive into DataFlow 1  
DataFlow1 Processor Group consists of four processors.  
The NiFi template is available for import.

![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/DataFlow2.png)

1.	**GetTwitter:** In NiFi we have the in-built GetTwitter processor which pulls tweets through twitter streaming API. Double click on the processor to populate our twitter credentials and the keywords to filter tweets on
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/GetTwitter.png)

2.	**EvaluateJSONPath:** EvaluateJsonPath is used to extract Json fields as attribute or content. Setting the Destination to flowfile-attribute ensures that each JSON Path will be extracted to the named attribute value. The twitter JSON values are the name of the keys of Tweet JSON data. 
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/EvaluateJSON.png)

3.	**RouteonAttribute:**  One of the most powerful features of NiFi is the ability to route FlowFiles based on their Attributes. The primary mechanism for doing this is the RouteOnAttribute Processor. Any number of user-defined properties can be added by clicking the "+" button in the top-right corner of the Properties tab in the Processor's Configure dialog. The most common strategy is the "Route to Property name" strategy. With this strategy selected, the Processor will expose a Relationship for each property configured. If the FlowFile's Attributes satisfy the given expression, a copy of the FlowFile will be routed to the corresponding Relationship. For example, in our case, FlowFile will be routed if the tweet’s message/text is not empty. This ensure that we do not have redundant data. ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/RouteonAttribute.png)

4. **PublishKafka:** Finally, we extract the metadata, key and value. Publish kafka key and value using PublishKafka processor. Note, that kafka topic name ‘tweets’ should be updated in PublishKafka processor. 
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PublishKafka.png)
