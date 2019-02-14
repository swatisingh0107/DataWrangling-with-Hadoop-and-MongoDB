# SparkMLApplication
We will build a SparkML application to build sentiment analysis model for Nike using Twitter Data

## Setup HDP Sandbox

1. Install Docker toolbox and run as Administrator
Prerequisites:
1. HDP requires minimum 10GB allocated to the virtual machine
2. Allocate maximum size to disk space to pull large images

Docker commands:
```
$ docker-machine rm default
$ docker-machine create -d virtualbox --virtualbox-disk-size "100000" --virtualbox-memory "10240" default
```
