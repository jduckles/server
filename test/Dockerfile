FROM ubuntu:20.04

RUN apt-get update -q -q 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata 
RUN apt-get install -y wget curl python3 python3-pip apt-transport-https software-properties-common
RUN pip3 install ansible apt-mirror-updater && apt-mirror-updater -c "http://ubuntu.mirrors.theom.nz/" 
RUN apt-get update -q -q
