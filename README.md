# SparkMLApplication (Project in Progress)
This tutorial will take you through the following steps to build a real time streaming application for analysis of Twitter Data. The brand to perform analysis for is Nike. Nike is one of the most famous corporations that can be found on the planet. In significant part, this is because of its outstanding marketing, which has made it a household name in countries situated all around the globe.

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
2. Create Twitter API Application
3. Setup Development Environment
4. Create Nifi DataFlow for tweets ingestion into Kafka
5. Build SparkSQL Application for data cleaning
6. Build sentiment analysis model using gradient boosting
7. Build spark streaming application to store sentiment score in kafka topic
8. Perform Analysis in Hive

# Sandbox Installation
## Setup HDP Sandbox

**Prerequisites:**
1. HDP Sandbox requires minimum 10GB allocated to the virtual machine
2. Allocate maximum size to disk space to pull large images

The complete deployment script for HDP sandbox is available [here](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/tree/master/hdp_deploy)

In order to store streaming data, perform real time analytics and artifical intelligence etc. we need to utilize the capabilites of both HDP and HDF to achieve our goal. For this type of data architecure, hybrid is an essential requirement. While HDP stores, processes, and analyzes large volumes of data, data flow and management is delievered through HDF's NiFi. **Connected Data Architecture** is currently supported by HDP 2.6.5 and HDF version 3.1.1. Hortonworks Connected Data Architecture (CDA) is composed of both Hortonworks DataFlow (HDF) and Hortonworks DataPlatform (HDP) sandboxes and allows you to play with both data-in-motion and data-at-rest frameworks simultaneously.

**Executing HDP Deployment Script in Docker**
Install [Git Bash](https://gitforwindows.org/) for Windows
Clone or download the repository in the Downloads folder
Open hdp-deploy folder
Right click to start Git-Bash in this folder.


