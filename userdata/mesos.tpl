#!/bin/bash

apt-get update
apt-get install -y awscli
apt install -y jq
export AWS_DEFAULT_REGION=us-east-1

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
CLUSTER_ID=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=ClusterId" | jq -r '.Tags[].Value')
CLUSTER_GROUP=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=ClusterGroup" | jq -r '.Tags[].Value')
ENVIRONMENT=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Environment" | jq -r '.Tags[].Value')
MESOS_TYPE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Tier" | jq -r '.Tags[].Value')
LOCAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PUBLIC_HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
AVAILABILITY_ZONE=$(curl -s curl http://169.254.169.254/latest/meta-data/placement/availability-zone)
ZOOKEEPER_IP=$(aws ec2 describe-instances --filters "Name=tag:ZookeeperInstance,Values=zookeeper-$CLUSTER_ID" | jq -r '.Reservations[].Instances[].PrivateIpAddress')
MASTER_IP=$(aws ec2 describe-instances --filters "Name=tag:MesosMasterInstance,Values=mesos-Master-$CLUSTER_ID" | jq -r '.Reservations[].Instances[].PrivateIpAddress')
MASTER_PUBLIC_HOSTNAME=$(aws ec2 describe-instances --filters "Name=tag:MesosMasterInstance,Values=mesos-Master-$CLUSTER_ID" | jq -r '.Reservations[].Instances[].PublicDnsName')

mkdir -p /home/ubuntu/apps/mesos
mkdir -p /home/ubuntu/apps/mesos/logs
mkdir -p /home/ubuntu/apps/marathon/logs
aws s3 cp s3://mesos-development/$ENVIRONMENT/compiled-source/mesos-1.9.0-060120.tar.gz /home/ubuntu/apps/mesos/mesos-1.9.0-060120.tar.gz
aws s3 cp s3://mesos-development/$ENVIRONMENT/conf/executor_environment_variables.json /home/ubuntu/apps/mesos/conf/executor_environment_variables.json
cd /home/ubuntu/apps/mesos/
mkdir work-dir
tar -xzf mesos-1.9.0-060120.tar.gz

cd /home/ubuntu/apps/marathon
mkdir conf
wget https://downloads.mesosphere.io/marathon/builds/1.8.222-86475ddac/marathon-1.8.222-86475ddac.tgz
tar -xzf marathon-1.8.222-86475ddac.tgz


mkdir -p /home/ubuntu/pki/mesos
aws s3 cp s3://mesos-development/$ENVIRONMENT/pki/cert-np.pem /home/ubuntu/pki/mesos/cert-np.pem
aws s3 cp s3://mesos-development/$ENVIRONMENT/pki/key-np.pem /home/ubuntu/pki/mesos/key-np.pem
aws s3 cp s3://mesos-development/$ENVIRONMENT/pki/mesoskeystore.jks /home/ubuntu/pki/mesos/mesoskeystore.jks

apt-get update
apt-get install -y tar wget git
apt-get install -y openjdk-8-jdk
apt-get install -y autoconf libtool
apt-get -y install build-essential python-dev python-six python-virtualenv libcurl4-nss-dev libsasl2-dev libsasl2-modules maven libapr1-dev libsvn-dev zlib1g-dev iputils-ping
apt install -y libssl-dev

mkdir /home/ubuntu/.aws/
printf "[default]\nregion = us-east-1" >> /home/ubuntu/.aws/config

echo "akka { ssl-config.loose.disableHostnameVerification=true }" >> /home/ubuntu/apps/marathon/conf/application.conf
echo "export MESOS_NATIVE_JAVA_LIBRARY=/data/apps/mesos/mesos-1.9.0/build/src/.libs/libmesos.so" >> /home/ubuntu/.profile
echo "export MESOS_EXECUTOR_ENVIRONMENT_VARIABLES=file://data/apps/mesos/conf/executor_environment_variables.json" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_ENABLED=true" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_VERIFY_SERVER_CERT=false" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_REQUIRE_CLIENT_CERT=true" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_HOSTNAME_VALIDATION_SCHEME=openssl" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_ENABLE_DOWNGRADE=false" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_KEY_FILE=/data/pki/mesos/key-np.pem" >> /home/ubuntu/.profile
echo "export LIBPROCESS_SSL_CERT_FILE=/data/pki/mesos/cert-np.pem" >> /home/ubuntu/.profile
echo "alias start-zoo=\"/data/apps/zookeeper/apache-zookeeper-3.6.1-bin/bin/zkServer.sh start\"" >> /home/ubuntu/.profile
echo "alias stop-zoo=\"/data/apps/zookeeper/apache-zookeeper-3.6.1-bin/bin/zkServer.sh stop\"" >> /home/ubuntu/.profile
echo "alias start-mesos-master=\"/data/apps/mesos/mesos-1.9.0/build/bin/mesos-master.sh --zk=zk://$ZOOKEEPER_IP:2181/mesos --quorum=1 --hostname=$PUBLIC_HOSTNAME --work_dir=/data/apps/mesos/work-dir >> /data/apps/mesos/logs/mesos-master.log 2>&1 &\"" >> /home/ubuntu/.profile
echo "alias start-mesos-agent=\"/data/apps/mesos/mesos-1.9.0/build/bin/mesos-agent.sh --master=$MASTER_IP:5050 --hostname=$PUBLIC_HOSTNAME --work_dir=/data/apps/mesos/work-dir --systemd_enable_support=false --containerizers=docker --attributes=\\\"availability_zone:$AVAILABILITY_ZONE;cluster_group:$CLUSTER_GROUP\\\" --executor_environment_variables=file:///data/apps/mesos/conf/executor_environment_variables.json --resources=\\\"ports(*):[80-81, 8000-9000, 31000-32000]\\\" >> /data/apps/mesos/logs/mesos-agent.log 2>&1 &\"" >> /home/ubuntu/.profile
echo "alias start-marathon=\"JAVA_OPTS=\"-Dconfig.file=/data/apps/marathon/conf/application.conf\" /data/apps/marathon/marathon-1.8.222-86475ddac/bin/marathon --https_port 8082 --ssl_keystore_path /data/pki/mesos/mesoskeystore.jks --ssl_keystore_password foobar --master zk://$ZOOKEEPER_IP:2181/mesos --zk zk://$ZOOKEEPER_IP:2181/marathon  --hostname $PUBLIC_HOSTNAME --disable_http >> /data/apps/marathon/logs/marathon.log 2>&1 &\"" >> /home/ubuntu/.profile


curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-cache policy docker-ce
apt-get install -y docker-ce
usermod -aG docker ubuntu

mkdir /data
mount --bind /home/ubuntu/ /data
chown -R ubuntu:ubuntu /home/ubuntu/apps/
chown -R ubuntu:ubuntu /home/ubuntu/pki/

if [ "$MESOS_TYPE" == "mesos-Master" ]; then
  runuser -l ubuntu -c "/data/apps/mesos/mesos-1.9.0/build/bin/mesos-master.sh --zk=zk://$ZOOKEEPER_IP:2181/mesos --quorum=1 --hostname=$PUBLIC_HOSTNAME --work_dir=/data/apps/mesos/work-dir >> /data/apps/mesos/logs/mesos-master.log 2>&1 &"
elif [ "$MESOS_TYPE" == "mesos-Agent" ]; then
  runuser -l ubuntu -c "/data/apps/mesos/mesos-1.9.0/build/bin/mesos-agent.sh --master=$MASTER_IP:5050 --hostname=$PUBLIC_HOSTNAME --work_dir=/data/apps/mesos/work-dir --systemd_enable_support=false --containerizers=docker --attributes=\"availability_zone:$AVAILABILITY_ZONE;cluster_group:$CLUSTER_GROUP\" --executor_environment_variables=file:///data/apps/mesos/conf/executor_environment_variables.json --resources=\"ports(*):[80-81, 8000-9000, 31000-32000]\" >> /data/apps/mesos/logs/mesos-agent.log 2>&1 &"
else
  runuser -l ubuntu -c "JAVA_OPTS=\"-Dconfig.file=/data/apps/marathon/conf/application.conf\" /data/apps/marathon/marathon-1.8.222-86475ddac/bin/marathon --https_port 8082 --ssl_keystore_path /data/pki/mesos/mesoskeystore.jks --ssl_keystore_password foobar --master zk://$ZOOKEEPER_IP:2181/mesos --zk zk://$ZOOKEEPER_IP:2181/marathon --hostname $PUBLIC_HOSTNAME  --disable_http >> /data/apps/marathon/logs/marathon.log 2>&1 &"
fi