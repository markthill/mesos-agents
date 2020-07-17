#!/bin/bash

echo "starting...."

####  Need to run this only on the active master instance

MESOS_TMP=/tmp/mesos

mkdir $MESOS_TMP

SLAVES_LOCATION=$MESOS_TMP/slaves.json
CLUSTER_GROUP_LOCATION=$MESOS_TMP/cluster_group.json
NAMES_LOCATION=$MESOS_TMP/names.json

curl --insecure https://localhost:5050/slaves > $SLAVES_LOCATION

# cat $SLAVES_LOCATION | jq '.slaves | group_by(.attributes.cluster_group) | .[] | map({"name": (.attributes.cluster_group),"cpus": (.resources.cpus),"gpus": (.resources.gpus), "mem": (.resources.mem)}) | {"name":(.[0].name), "cpus": (map(.cpus) | add), "gpus": (map(.gpus) | add), "mem": (map(.mem) | add)} ' | jq . -s > $CLUSTER_GROUP_LOCATION

cat $SLAVES_LOCATION | jq '.slaves | group_by(.attributes.cluster_group) | .[] | map({"name": (.attributes.cluster_group),"cpus": (.resources.cpus),"used_cpus": (.used_resources.cpus),"gpus": (.resources.gpus),"used_gpus": (.used_resources.gpus), "mem": (.resources.mem), "used_mem": (.used_resources.mem)}) | {"name":(.[0].name), "cpus": (map(.cpus) | add), "used_cpus": (map(.used_cpus) | add), "gpus": (map(.gpus) | add), "used_gpus": (map(.used_gpus) | add), "mem": (map(.mem) | add), "used_mem": (map(.used_mem) | add)} ' | jq . -s > $CLUSTER_GROUP_LOCATION

cat $SLAVES_LOCATION | jq '.slaves | group_by(.attributes.cluster_group) | .[] | map({"name": (.attributes.cluster_group),"cpus": (.resources.cpus),"gpus": (.resources.gpus),"mem": (.resources.mem)}) | {"name":(.[0].name), "cpus": (map(.cpus) | add), "gpus": (map(.gpus) | add), "mem": (map(.mem) | add)} ' | jq . -s | jq -r '.[].name' > $NAMES_LOCATION


cat $NAMES_LOCATION | while read line
do
        size_cpus=$( cat $CLUSTER_GROUP_LOCATION | jq --arg LINE "$line" '.[] | select(.name==$LINE) | .cpus' )
        size_used_cpus=$( cat $CLUSTER_GROUP_LOCATION | jq --arg LINE "$line" '.[] | select(.name==$LINE) | .used_cpus' )
        echo "size_cpus: $size_cpus"
        echo "size_used_cpus: $size_used_cpus"

        #percent_used_cpus=$(($size_used_cps / $size_cpus))
        #percent_used_cpus=$((1/2))

        size_mem=$( cat $CLUSTER_GROUP_LOCATION | jq --arg LINE "$line" '.[] | select(.name==$LINE) | .mem' )
        size_used_mem=$( cat $CLUSTER_GROUP_LOCATION | jq --arg LINE "$line" '.[] | select(.name==$LINE) | .used_mem' )
        aws cloudwatch put-metric-data --metric-name total-cpus --dimensions Group=devops  --namespace "Mesos" --value $size_cpus
        aws cloudwatch put-metric-data --metric-name total-used-cpus --dimensions Group=devops  --namespace "Mesos" --value $size_used_cpus
        aws cloudwatch put-metric-data --metric-name total-memory --dimensions Group=devops  --namespace "Mesos" --value $size_mem
        aws cloudwatch put-metric-data --metric-name total-used-memory --dimensions Group=devops  --namespace "Mesos" --value $size_used_mem
        #aws cloudwatch put-metric-data --metric-name percent_used_cpus --dimensions Group=devops  --namespace "Mesos" --value $percent_used_cpus
done

echo "ending..."
echo "   "