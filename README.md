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
5. [Build SparkSQL Application for data cleaning](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#building-sentiment-analysis-model)
6. [Build spark streaming application to store sentiment score in kafka](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#spark-streaming-application-to-deploy-model)
7. [Perform Analysis in MongoDB](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis#data-analysis-in-mongoDB)

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

## Deep Dive into DataFlow 2
**ConsumeKafka**: This processor consumes messages from kafka topic ‘tweetsSentiment’ and generates flowfile for each message. The FlowFile moves to the EvaluateJSONPath which is a copy of the ‘PullKeyAttributes’ processor from DataFlow1.
**AttributesToJSON**: This processor generates a JSON representation of the input FlowFile Attributes. The resulting JSON will be written to a FlowFile as content.
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/AttributestoJSON.png)

**RouteOnAttribute**: FlowFile will be routed if the tweet’s message has a timestamp and a sentiment score attached to it. This ensures that we have quality data to perform sentiment analysis.
```
${twitter.unixtime:isEmpty():not():and(${twitter.sentiment:isEmpty():not()})}
```
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/AttributestoJSON.png)

**PutMongo:** Once verified that the message has a sentiment score attached to it, we will now write each JSON message to MongoDB database.collection ‘tweets_sentiment.social_media_sentiment’. 
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PutMongo.png)

## Start Process Group GetNikeTweets

![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/StartProcess.png)
Once we start the process group, we can see data being read from the twitter API and consumed by kafka topic ‘tweets’. Now let’s see an example of a tweet being ingested into kafka.
1.	Enter the process group ‘GetNikeTweets’ and right click on processor ‘Publishkafka.
2.	Click on ‘View data provenance’
3.	Click on the i icon for the event type ‘SEND’
4.	Click on ‘CONTENT’ tab
5.	On the Output Claim, choose VIEW
You will be able to see the data NiFi sent to the external process Kafka. The data below shows tweets dataset.

![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/ExampleJSON.png)

# Building Sentiment Analysis Model
For the purpose of this tutorial, Hortonworks provided with a set of tweets for building and training our sentiment classification model. We will create a Zeppelin notebook that uses Scala spark interpreter  to clean our raw twitter data. Our Nifi flow already handles missing data. It drops the tweets that have empty message and publishes only complete tweet messages to kafka topic ‘tweet’. In this phase, we will classify our tweet sample data set into happy or sad sentiment based on the presence of these words.

## Prerequisites
Start HDFS, YARN, Zeppelin and Spark2 in Ambari

## Load data into Spark
```
import scala.util.{Success, Try}
val sqlContext = new org.apache.spark.sql.SQLContext(sc)
var tweetDF = sqlContext.read.json("hdfs:///sandbox/tutorial-files/770/tweets_staging/*")
tweetDF.show()
```
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/LoadSampleData.png)
[Ref](https://hortonworks.com/tutorial/building-a-sentiment-analysis-application/section/4/)

In the following code we’ll clean-up the data to prevent bias in the model. We will use SparkSQL to retain equal number of happy and sad tweets and ignore the rest.

```
%spark2
var messages = tweetDF.select("msg")
println("Total messages: " + messages.count())

//Subset of messages that contain happy
var happyMessages = messages.filter(messages("msg").contains("happy"))
val countHappy = happyMessages.count()
println("Number of happy messages: " +  countHappy)

//Subset of messages that contain sad
var unhappyMessages = messages.filter(messages("msg").contains(" sad"))
val countUnhappy = unhappyMessages.count()
println("Unhappy Messages: " + countUnhappy)

//Lower boundary of the two subsets
val smallest = Math.min(countHappy, countUnhappy).toInt
 
//Create a dataset with equal parts happy and unhappy messages based on lower boundary
var tweets = happyMessages.limit(smallest).unionAll(unhappyMessages.limit(smallest))
```
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/SplitData.png)

First, we will label each tweet with 1 or 0 based on the presence of word ‘happy’ or ‘sad’ respectively. For convenience we convert the Spark Dataframe to an RDD which lets us easily transform data using the map function. An RDD is building block of spark. No matter which abstraction Dataframe or Dataset we use, internally final computation is done on RDDs. After labeling, we will remove these words from the messages and will use the rest of the collection of words to infer the sentiment.

```
%spark2
val messagesRDD = tweets.rdd
//We use scala's Try to filter out tweets that couldn't be parsed
val goodBadRecords = messagesRDD.map(
  row =>{
    Try{
      val msg = row(0).toString.toLowerCase()
      var isHappy:Int = 0
      if(msg.contains(" sad")){
        isHappy = 0
      }else if(msg.contains("happy")){
        isHappy = 1
      }
      var msgSanitized = msg.replaceAll("happy", "")
      msgSanitized = msgSanitized.replaceAll("sad","")
      //Return a tuple
      (isHappy, msgSanitized.split(" ").toSeq)
    }
  }
)
 
//We use this syntax to filter out exceptions
val exceptions = goodBadRecords.filter(_.isFailure)
println("total records with exceptions: " + exceptions.count())
exceptions.take(10).foreach(x => println(x.failed))
var labeledTweets = goodBadRecords.filter((_.isSuccess)).map(_.get)
println("total records with successes: " + labeledTweets.count())
```
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/LabeledTweetsOutput.png)

Most of ML algorithms require us to represent input data as real number matrix. Process of converting raw data to real number matrix is called feature engineering, and hashing trick is a feature engineering technique. In Spark we’re using HashingTF for feature hashing.
Gradient Boosting expects as input a vector (feature array) of fixed length, so we need a way to convert our tweets into some numeric vector that represents that tweet. A standard way to do this is to use the hashing trick, in which we hash each word and index it into a fixed-length array. What we get back is an array that represents the count of each word in the tweet. This approach is called the bag of words model, which means we are representing each sentence or document as a collection of discrete words and ignore grammar or the order in which words appear in a sentence. 

```
%spark2
val hashingTF = new HashingTF(2000)
 
//Map the input strings to a tuple of labeled point + input text
val input_labeled = (labeledTweets.map(
  t => (t._1, hashingTF.transform(t._2)))
  .map(x => new LabeledPoint((x._1).toDouble, x._2)))
input_labeled.take(10).foreach(println) 
//We're keeping the raw text for inspection later
var sample = (labeledTweets.take(1000).map(
  t => (t._1, hashingTF.transform(t._2), t._2))
  .map(x => (new LabeledPoint((x._1).toDouble, x._2), x._3)))
```
## Gradient Boosting Classification Model
Gradient boosting is a machine learning technique for regression and classification problems, which produces a prediction model in the form of an ensemble of weak prediction models, typically decision trees. (Wikipedia definition). Boosting is a method of converting weak learners into strong learners. The tuning parameters we’re using here are:
-number of iterations (passes over the data)
-Max Depth of each decision tree
In practice when building machine learning models we usually have to test different settings and combinations of tuning parameters until we find the model that fits the data best. For this reason, it’s usually best to first train the model on a subset of data or with a small number of iterations. This lets us quickly experiment with different tuning parameter combinations.

```
// Split the data into training and validation sets (30% held out for validation testing)
val splits = input_labeled.randomSplit(Array(0.7, 0.3))
val (trainingData, validationData) = (splits(0), splits(1))
val boostingStrategy = BoostingStrategy.defaultParams("Classification")
boostingStrategy.setNumIterations(20) //number of passes over our training data
boostingStrategy.treeStrategy.setNumClasses(2) //We have two output classes: happy and sad
boostingStrategy.treeStrategy.setMaxDepth(5)
//Depth of each tree. Higher numbers mean more parameters, which can cause overfitting.
//Lower numbers create a simpler model, which can be more accurate.
val model = GradientBoostedTrees.train(trainingData, boostingStrategy)
```

Let’s evaluate the model to see how it performed against our training and test set.
```
%spark2
// Evaluate model on test instances and compute test error
var labelAndPredsTrain = trainingData.map { point =>
  val prediction = model.predict(point.features)
  Tuple2(point.label, prediction)
}
 
var labelAndPredsValid = validationData.map { point =>
  val prediction = model.predict(point.features)
  Tuple2(point.label, prediction)
}
 
//Since Spark has done the heavy lifting already, lets pull the results back to the driver machine.
//Calling collect() will bring the results to a single machine (the driver) and will convert it to a Scala array.
 
//Start with the Training Set
val results = labelAndPredsTrain.collect()
 
var happyTotal = 0
var unhappyTotal = 0
var happyCorrect = 0
var unhappyCorrect = 0
results.foreach(
  r => {
    if (r._1 == 1) {
      happyTotal += 1
    } else if (r._1 == 0) {
      unhappyTotal += 1
    }
    if (r._1 == 1 && r._2 ==1) {
      happyCorrect += 1
    } else if (r._1 == 0 && r._2 == 0) {
      unhappyCorrect += 1
    }
  }
)
println("unhappy messages in Training Set: " + unhappyTotal + " happy messages: " + happyTotal)
println("happy % correct: " + happyCorrect.toDouble/happyTotal)
println("unhappy % correct: " + unhappyCorrect.toDouble/unhappyTotal)
 
val testErr = labelAndPredsTrain.filter(r => r._1 != r._2).count.toDouble / trainingData.count()
println("Test Error Training Set: " + testErr)
 
  
//Compute error for validation Set
val results = labelAndPredsValid.collect()
 
var happyTotal = 0
var unhappyTotal = 0
var happyCorrect = 0
var unhappyCorrect = 0
results.foreach(
  r => {
    if (r._1 == 1) {
      happyTotal += 1
    } else if (r._1 == 0) {
      unhappyTotal += 1
    }
    if (r._1 == 1 && r._2 ==1) {
      happyCorrect += 1
    } else if (r._1 == 0 && r._2 == 0) {
      unhappyCorrect += 1
    }
  }
)
println("unhappy messages in Validation Set: " + unhappyTotal + " happy messages: " + happyTotal)
println("happy % correct: " + happyCorrect.toDouble/happyTotal)
println("unhappy % correct: " + unhappyCorrect.toDouble/unhappyTotal)
 
val testErr = labelAndPredsValid.filter(r => r._1 != r._2).count.toDouble / validationData.count()
```
Depth:4 Iterations: 25
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/ModelEvaluation.png)

Once our model is as accurate as we can make it, we can export it for production use. Models trained with Spark can be easily loaded back into a Spark Structured Streaming workflow for use in production.

```
%spark2
model.save(sc, "hdfs:///sandbox/tutorial-files/770/tweets/RandomForestModel")
```
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/RandomForestModel.png)


# Spark Streaming Application to Deploy Model
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/SparkApplication.png)

We configured our Spark streaming application as follows:
```
spark {

  kafkaBrokers {
    kafkaBrokerHDF: "sandbox-hdf.hortonworks.com:6667"
    kafkaBrokerHDP: "sandbox-hdp.hortonworks.com:6667"
  }

  appName = "SentimentModel"
  messageFrequency = 200 //milliseconds
  modelLocation = "hdfs:///sandbox/tutorial-files/770/tweets/RandomForestModel"

  kafkaTopics {
    tweetsRaw: "tweets"
    tweetsWithSentiment: "tweetsSentiment"
  }
}
```
Our Spark Streaming Application contains two classes. ‘Predictor’ class converts the tweet into a vector using Hashing transformation and predicts the sentiment. The Collect class collects the tweet, applies the predict object from Predictor class and appends the sentiment score to the outgoing tweet.
### Predictor.scala
```
class Predictor(model: GradientBoostedTreesModel){// Function to predict the sentiment on vectorized tweet msg
  def predict(tweet:String): Double ={
    if(tweet == null || tweet.length == 0)
      throw new RuntimeException("Tweet is null")
    val features = vectorize(tweet)
    return model.predict(features)
  } //Function to vectorize raw tweet msg
val hashingTF = new HashingTF(2000)
  def vectorize(tweet:String):Vector={
    hashingTF.transform(tweet.split(" ").toSeq)
  }
 }
```
### Collect.scala
```
val options = new CollectOptions(
      config.getString("spark.kafkaBrokers.kafkaBrokerHDF"),
      config.getString("spark.kafkaBrokers.kafkaBrokerHDP"),
      config.getString("spark.kafkaTopics.tweetsRaw"),
      config.getString("spark.kafkaTopics.tweetsWithSentiment"),
      config.getString("spark.appName"),
      config.getString("spark.modelLocation")
    )
 
    val spark = SparkSession
      .builder
      .appName("DeploySentimentModel")
      .getOrCreate()
    spark.sparkContext.setLogLevel("ERROR")// Create DataSet representing the stream of input lines from kafka
 
    val rawTweets = spark
      .readStream
      .format("kafka")
      .option("kafka.bootstrap.servers", options.kafkaBrokerHDP)
      .option("subscribe", options.tweetsTopic)
      .load()
      .selectExpr("CAST(value AS STRING)")
      .as[String]
// Create DataSet representing the stream of input lines from kafka
    val rawTweets = spark
      .readStream
      .format("kafka")
      .option("kafka.bootstrap.servers", options.kafkaBrokerHDP)
      .option("subscribe", options.tweetsTopic)
      .load()
      .selectExpr("CAST(value AS STRING)")
      .as[String]
 
    rawTweets.printSchema()
    //Our Predictor class can't be serialized, so we're using mapPartition to create a new model instance for each partition.
    val tweetsWithSentiment = rawTweets.mapPartitions((iter) => {
      val pred = new Predictor(model
      val parser = new JsonParser()
      iter.map(
        tweet =>
          //For error handling, we're mapping to a Scala Try and filtering out records with errors.
          Try {
            val element = parser.parse(tweet).getAsJsonObject
            val msg = element.get("text").getAsString
            val sentiment = pred.predict(msg)
            element.addProperty("sentiment", pred.predict(tweet))
            val json = element.toString
            println(json)
            json
          }
      ).filter(_.isSuccess).map(_.get)
    })
 
    val query = tweetsWithSentiment.writeStream
      .outputMode("append")
      .format("console")
      .start()
 
    //Push back to Kafka
    val kafkaProps = new Properties()
    //props.put("metadata.broker.list",  options.kafkaBrokerList)
    kafkaProps.put("bootstrap.servers", options.kafkaBrokerHDF)
    kafkaProps.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer")
    kafkaProps.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer")
 
    tweetsWithSentiment
      .writeStream
      .foreach(
        new ForeachWriter[(String)] {
 
          //KafkaProducer can't be serialized, so we're creating it locally for each partition.
          var producer:KafkaProducer[String, String] = null
 
          override def process(value: (String)) = {
            val message = new ProducerRecord[String, String](options.tweetsWithSentimentTopic, null,value)
            println("sending windowed message: " + value)
            producer.send(message)
          }
 
          override def close(errorOrNull: Throwable) = ()
 
          override def open(partitionId: Long, version: Long) = {
            producer = new KafkaProducer[String, String](kafkaProps)
            true
          }
        }).start()
 
    query.awaitTermination()
```

###  Copying Sentiment model to HDFS
We copied the jar version of our spark streaming application into HDFS

![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/CopyJar.png)

Now we will deploy the jar file on our local HDP and can see the output as Spark scores each tweet.
```
/usr/hdp/current/spark2-client/bin/spark-submit --class "main.scala.Collect" --master local[4] root/SentimentModel-assembly-0.1.jar
```
 Once the jar is deployed, the application starts listening for tweets
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/KafkaListener.png)
 
 We can see below that sentiment score is being assigned
  ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/SentimentScore.png)
  
  # Data Analysis in MongoDB
  When we load data into MongoDB, we see that all attributes have default datatype as String. This is because Nifi Processor AttributestoJSON converts all attributes to String. We can use the aggregation framework in MongoDB to further process data into our desired format. Below is one of the first records that was streamed through our flow and loaded into MongoDB.
  
![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/MongoDBCollection.png)
    
 We will now transform this document and all the other documents into desired output. We will use the aggregation framework and create a data pipeline as follows

![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/AggregationPipeline.png)
```
$project:/**
* specifications - The fields to
 *   include or exclude.
 */
{
  tweet_id:'$tweet_id',
  created_at:{$dateFromString:{dateString:'$time'}},
  user:'$handle',
  followers:{$toInt:'$followers'},
  msg:'$msg',
 hashtags:{$concat:['$hashtags',',','$hashtag1',',','$hashtag2',',','$hashtag3',',','$hashtag4']},
  sentiment:{$toInt:{$toDecimal:'$sentiment'}},
  retweeted_from:'$retweeted_from',
  Promoter_followers:{
   $cond: { if: {$gt:[{$strLenCP:'$Promoter_followers'},0]}, then:{$toInt:'$Promoter_followers'}, else: 0 } 
  },
  retweet_count:{
   $cond: { if: {$gt:[{$strLenCP:'$retweet_count'},0]}, then: {$toInt:'$retweet_count'}, else: 0 } 
    
  }
}
 
$out:’Processed_social_media_sentiment’
```
 We will store the result in a separate collection.
 This is how the processed document looks like
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/ProcessedTweet.png)

Upon quickly going through some of the documents, I realized that the retweeted_from , retweet_count and promoter_followers fields were empty. This is because we filtered tweets with empty messages in the Nifi flow. However, this is an important attribute as we can gauge the reach of a tweets based on its retweet count. So let’s modify the nifi flow to include retweets as well.
We modified the condition from Dataflow1 in RouteonAttribute for ${twitter.handle:isEmpty():not()}
Let’s rerun the flow to analyze new tweet documents. We can see that we are getting are now recording retweets as well. After running for few minutes we have over 3.3K records or documents. 

 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/Retweets.png)
 
# Some Insights:
**Most popular retweets:**
{retweet_count: {$gte:100000}}
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/Populartweets.png)

Both their most popular ads were received negatively. First is the Ad with Kaepernick. Although Nike made [huge profits](https://www.vox.com/2018/9/24/17895704/nike-colin-kaepernick-boycott-6-billion) after releasing this ad, it is causing a huge debate around whether kneeling during the national anthem was insulting for the American soldiers or protest again police brutality. However, this is what Nike is famous for. They win the odds by striking a debate about important topics.
Their other ad focusing on women athletes also has been received well with the audience and has been retweeted 195K times since its release in Feb 2019.
It is also important to understand that these ads with negative sentiment have been hugely popular. We can safely say that ads that bring out bias have been beneficial for Nike in striking some kind of chord with the audience.
Since our sentiment is only 1 and 0, it also appears that tweets with neutral sentiment are also getting recorded as 0. So lets run some analysis on tweets with sentiment score 1.

**Most popular positive tweet**
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PositiveTweet.png)

The Nike Ad by Kyrie Irving was retweeted 17K times. It is still popular since its release in November 2018.

**Popular Handles**
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PopularHandle.png)

Also we can see the most popular influencer handles based on the analysis of only 3.3k documents on twitter are Kaepernick, Nike, KyrieIrving, Cristiano, ESPNNBA, nikestore, nikebasketball and footlocker. 
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/ChangeinFollowers.png)
 Here we can see that ESPNNBA has had a decrease of followers in a few minutes from 6028988 to 6028981. We also see a fluctuation in the number of followers over time.The number is small due to a small time window of the data captured.
Most gathering the count of most popular hashtags, I exported the hashtags column from Processed_social_media_sentiment and loaded into python for analysis

**Popular Hashtags**
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PopularHashtags.png)
 ![alt text](https://github.com/swatisingh0107/NikeRealTimeDataAnalysis/blob/master/Images/PopularHashtags2.png)

MFFL is a news handle for Dallas Maverick. Nike is the apparel and shoes partner of this popular basketball team.


