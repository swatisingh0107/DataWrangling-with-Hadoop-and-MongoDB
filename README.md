# SparkMLApplication (Project in Progress)
We will build a SparkML application to build sentiment analysis model for Nike using Twitter Data.
We will then visualize various metrics using Hive mapping to HBase table.

## Setup HDP Sandbox

1. Install Docker toolbox and run as Administrator

Prerequisites:
1. HDP Sandbox requires minimum 10GB allocated to the virtual machine
2. Allocate maximum size to disk space to pull large images

Docker commands:
```
$ docker-machine rm default
$ docker-machine create -d virtualbox --virtualbox-disk-size "100000" --virtualbox-memory "10240" default
```

## Troubleshooting
Docker toolbox required the working directory to be shareable to be able to mount the proxy sandbox folders to the container.\
To mount contents of a folder to the container, follow the folowing steps:\
Navigate to ~/.docker/machine/machines/default/default \
Edit the VBOX-PREV file with the following additon
```
<SharedFolders>
        <SharedFolder name="c/Users" hostPath="\\?\c:\Users" writable="true" autoMount="true"/>
        -- New addition
        <SharedFolder name="WorkDir" hostPath="\\?\<insert your path here>"
                      writable="true" autoMount="true"/>
      </SharedFolders>
```
## HDP Deployment

Download deployment scripts for Docker from [here](https://hortonworks.com/downloads/#sandbox)

