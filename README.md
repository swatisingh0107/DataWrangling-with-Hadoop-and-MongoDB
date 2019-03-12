# SparkMLApplication (Project in Progress)
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
4. Create Nifi DataFlow for tweets ingestion into Kafka
5. Build SparkSQL Application for data cleaning
6. Build sentiment analysis model using gradient boosting
7. Build spark streaming application to store sentiment score in kafka topic
8. Perform Analysis in Hive

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
HDF Sandbox:  http://sandbox-hdf.hortonworks.com:8080

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

