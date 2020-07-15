## Configuring servers for Groups

Should you want to run a group of agents for a particular group (i.e. "devops" or "arroe")

Create a group of servers for devops

The following commands require specific environment variable to function correctly as state is stored remotely.

1. CLUSTER_GROUP - the name of the group (i.e. devops)
1. GROUP_VERSION - the version of the group.  This is supplied so that later a group can be replaced (i.e. you want to change the instance types)
    * You would be required to drain the old groups instances prior to destroying the group
    * Draining procedures to come
       * something like this:  
       ```
        curl --insecure -d '{"type": "DRAIN_AGENT", "drain_agent": {"agent_id": {"value": "4194ebfa-77bf-4f95-8830-48750098e412-S12"}}}' -H 'Content-Type: application/json' https://ec2-54-163-63-12.compute-1.amazonaws.com:5050/api/v1
       ```

```
rm -rf .terraform
export CLUSTER_GROUP=devops && export GROUP_VERSION=1 && bash -c 'terraform init -input=false -backend-config "key=cluster/mesos/agenta-$CLUSTER_GROUP-v$GROUP_VERSION.tfstate"'
terraform workspace new development
terraform workspace select development
terraform apply -var="cluster_group=devops" -var="group_version=1"
terraform destroy -var="cluster_group=devops" -var="group_version=1"
```

Create a group of servers for arroe
```
rm -rf .terraform
export CLUSTER_GROUP=arroe && export GROUP_VERSION=1 && bash -c 'terraform init -input=false -backend-config "key=cluster/mesos/agenta-$CLUSTER_GROUP-v$GROUP_VERSION.tfstate"'
terraform workspace new development
terraform workspace select development
terraform apply -var="cluster_group=arroe" -var="group_version=1" -var="cluster_id=65a8764a191a7ccc"
terraform destroy -var="cluster_group=arroe" -var="group_version=1" -var="cluster_id=65a8764a191a7ccc"
```