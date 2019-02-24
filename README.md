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

<!-- ## Troubleshooting
1. Docker toolbox required the working directory to be shareable to be able to mount the proxy sandbox folders to the container.\
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
2.  Error response from daemon: cgroups: cannot find cgroup mount destination: unknown. \
Solution
```
$ docker-machine ssh default "sudo mkdir /sys/fs/cgroup/systemd"
$ docker-machine ssh default "sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd"
```
-->
## HDP Deployment

Download deployment scripts for Docker from [here](https://hortonworks.com/downloads/#sandbox)
1. For simplest installation, make sure that you download and extract the scripts in your Download folder  
2. Run Git Bash in your extracted folder and execute the deployment script  docker-deploy-hdp<version>  
        ```
        $ sh docker-deploy-hdp30
        ```  

**Troubleshooting for proxy deploy**  
If you get docker error for invalid reference format, replace your system path in proxy-deploy.sh script with $(pwd) to map volumes  
For example:  
In my [script](https://github.com/swatisingh0107/SparkMLApplication/blob/master/HDP3.0.1/sandbox/proxy/proxy-deploy.sh), I've replaced \C:\Users\swati\Downloads\HDP3.0.1 with \\$PWD    
Rexecute proxy-deploy in Git Bash
```
$ sandbox/proxy/proxy-deploy.sh
```  

