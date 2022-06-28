# OpenShift 4 UPI on Azure Cloud

This [terraform](terraform.io) implementation will deploy OpenShift 4.x into an Azure VNET, with two subnets for controlplane and worker nodes.  Traffic to the master nodes is handled via a pair of loadbalancers, one for internal traffic and another for external API traffic.  Application loadbalancing is handled by a third loadbalancer that talks to the router pods on the infra nodes.  Worker, Infra and Master nodes are deployed across 3 Availability Zones

![Topology](./media/topology.svg)

## Prerequisites

1. [Configure DNS](https://github.com/openshift/installer/blob/d0f7654bc4a0cf73392371962aef68cd9552b5dd/docs/user/azure/dnszone.md)

2. [Create a Service Principal](https://github.com/openshift/installer/blob/d0f7654bc4a0cf73392371962aef68cd9552b5dd/docs/user/azure/credentials.md) with proper IAM roles

3. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Minimal TFVARS file

```terraform
azure_region = "eastus2"
cluster_name = "ocp46"

# From Prereq. Step #1
base_domain                           = "azure.example.com"
azure_base_domain_resource_group_name = "openshift4-common-rg"

# From Prereq. Step #2
azure_subscription_id  = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
azure_tenant_id        = "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"
azure_client_id        = "ZZZZZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZZZZZZZZZ"
azure_client_secret    = "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
```

## Customizable Variables

| Variable                              | Description                                                    | Default         | Type   |
| ------------------------------------- | -------------------------------------------------------------- | --------------- | ------ |
| azure_subscription_id                 | Subscription ID for Azure Account                              | -               | string |
| azure_tenant_id                       | Tenant ID for Azure Subscription                               | -               | string |
| azure_client_id                       | Application Client ID (from Prereq Step #2)                    | -               | string |
| azure_client_secret                   | Application Client Secret (from Prereq Step #2)                | -               | string |
| azure_region                          | Azure Region to deploy to                                      | -               | string |
| cluster_name                          | Cluster Identifier                                             | -               | string |
| master_count                          | Number of master nodes to deploy                               | 3               | string |
| worker_count                          | Number of worker nodes to deploy                               | 3               | string |
| infra_count                           | Number of infra nodes to deploy                                | 0               | string |
| machine_v4_cidrs                      | IPv4 CIDR for OpenShift VNET                                   | \[10.0.0.0/16\] | list   |
| machine_v6_cidrs                      | IPv6 CIDR for OpenShift VNET                                   | \[\]               | list   |
| base_domain                           | DNS name for your deployment                                   | -               | string |
| azure_base_domain_resource_group_name | Resource group where DNS is hosted.  Must be on zame region.   | -               | string |
| azure_bootstrap_vm_type               | Size of bootstrap VM                                           | Standard_D4s_v3 | string |
| azure_master_vm_type                  | Size of master node VMs                                        | Standard_D4s_v3 | string |
| azure_infra_vm_type                   | Size of infra node VMs                                         | Standard_D4s_v3 | string |
| azure_worker_vm_type                  | Sizs of worker node VMs                                        | Standard_D4s_v3 | string |
| openshift_cluster_network_cidr        | CIDR for Kubernetes pods                                       | 10.128.0.0/14   | string |
| openshift_cluster_network_host_prefix | Detemines the number of pods a node can host.  23 gives you 510 pods per node. | 23 | string |
| openshift_service_network_cidr        | CIDR for Kubernetes services                                   | 172.30.0.0/16   | string |
| openshift_pull_secret                 | Filename that holds your OpenShift [pull-secret](https://cloud.redhat.com/openshift/install/azure/installer-provisioned) | - | string |
| azure_master_root_volume_size         | Size of master node root volume                                | 512             | string |
| azure_worker_root_volume_size         | Size of worker node root volume                                | 128             | string |
| azure_infra_root_volume_size          | Size of infra node root volume                                 | 128             | string |
| azure_master_root_volume_type         | Storage type for master root volume                            | Premium_LRS     | string |
| openshift_version                     | Version of OpenShift to deploy.                                | 4.6.13          | strig |
| bootstrap_completed                   | Control variable to delete bootstrap node after initialization | false           | bool |
| azure_private                         | If set to `true` will deploy `api` and `*.apps` endpoints as private LoadBalancers | - | bool |
| azure_extra_tags                      | Extra Azure tags to be applied to created resources            | {}              | map |
| airgapped                             | Configuration for an AirGapped environment                     | [AirGapped](AIRGAPPED.md) | map |
| azure_environment                     | The target Azure cloud environment for the cluster             | public | string |
| azure_master_availability_zones       | The availability zones in which to create the masters. The length of this list must match `master_count`| ["1","2","3"]| list |
| azure_preexisting_network             | Specifies whether an existing network should be used or a new one created for installation. | false | bool |
| azure_resource_group_name             | The name of the resource group for the cluster. If this is set, the cluster is installed to that existing resource group otherwise a new resource group will be created using cluster id. | -               | string |
| azure_network_resource_group_name     | The name of the network resource group, either existing or to be created | `null` | string |
| azure_virtual_network                 | The name of the virtual network, either existing or to be created | `null` | string |
| azure_control_plane_subnet            | The name of the subnet for the control plane, either existing or to be created | `null` | string |
| azure_compute_subnet                  | The name of the subnet for worker nodes, either existing or to be created | `null` | string |
| azure_emulate_single_stack_ipv6       | This determines whether a dual-stack cluster is configured to emulate single-stack IPv6 | false | bool |
| azure_outbound_user_defined_routing   | This determined whether User defined routing will be used for egress to Internet. When `false`, Standard LB will be used for egress to the Internet. | false | bool |
| use_ipv4                              | This determines wether your cluster will use IPv4 networking | true | bool |
| use_ipv6                              | This determines wether your cluster will use IPv6 networking | false | bool |
| proxy_config                          | Configuration for Cluster wide proxy | [AirGapped](AIRGAPPED.md)| map |
| openshift_ssh_key | Path to your own SSH Public Key.  If none provided it will create one for you | - | string |
| openshift_additional_trust_bundle | Path to your trusted CA bundle in pem format | - | string |
| openshift_byo_dns | If set to true, we will not create Azure Public/Private DNS zones.  **You'll need to manually create `api`, `api-int` and `*.apps` DNS records** | false | bool |

## Deploy with Terraform

1. Clone github repository

    ```bash
    git clone git@github.com:ibm-cloud-architecture/terraform-openshift4-azure.git
    ```

2. Create your `terraform.tfvars` file

3. Deploy with terraform

    ```bash
    terraform init
    terraform plan -var-file="variables-azure.tfvars"
    terraform apply -var-file="variables-azure.tfvars" -auto-approve

    terraform apply -destroy -var-file="variables-azure.tfvars"
    ```

4. Destroy bootstrap node

    ```bash
    TF_VAR_bootstrap_complete=true terraform apply -var-file="variables-azure.tfvars"
    ```

5. To access your cluster

    ```bash
    $ cd YOUR_PROJECT_DIRECTORY
    $ cp installer-files/auth/kubeconfig ~/.kube/config
    $ oc get nodes
    NAME                                 STATUS   ROLES          AGE   VERSION
    fs2021-hv0eu-infra-eastus21-6kqlt    Ready    infra,worker   20m   v1.19.0+3b01205
    fs2021-hv0eu-infra-eastus22-m826l    Ready    infra,worker   20m   v1.19.0+3b01205
    fs2021-hv0eu-infra-eastus23-qf4kc    Ready    infra,worker   19m   v1.19.0+3b01205
    fs2021-hv0eu-master-0                Ready    master         30m   v1.19.0+3b01205
    fs2021-hv0eu-master-1                Ready    master         30m   v1.19.0+3b01205
    fs2021-hv0eu-master-2                Ready    master         30m   v1.19.0+3b01205
    fs2021-hv0eu-worker-eastus21-bw8nq   Ready    worker         19m   v1.19.0+3b01205
    fs2021-hv0eu-worker-eastus22-rtwwh   Ready    worker         20m   v1.19.0+3b01205
    fs2021-hv0eu-worker-eastus23-tsw44   Ready    worker         20m   v1.19.0+3b01205
    ```

## Infra and Worker Node Deployment

Deployment of Openshift Worker and Infra nodes is handled by the machine-operator-api cluster operator.

```bash
$ oc get machineset -n openshift-machine-api
NAME                           DESIRED   CURRENT   READY   AVAILABLE   AGE
fs2021-hv0eu-infra-eastus21    1         1         1       1           35m
fs2021-hv0eu-infra-eastus22    1         1         1       1           35m
fs2021-hv0eu-infra-eastus23    1         1         1       1           35m
fs2021-hv0eu-worker-eastus21   1         1         1       1           35m
fs2021-hv0eu-worker-eastus22   1         1         1       1           35m
fs2021-hv0eu-worker-eastus23   1         1         1       1           35m

$ oc get machines -n openshift-machine-api
NAME                                 PHASE     TYPE              REGION    ZONE   AGE
fs2021-hv0eu-infra-eastus21-6kqlt    Running   Standard_D4s_v3   eastus2   1      31m
fs2021-hv0eu-infra-eastus22-m826l    Running   Standard_D4s_v3   eastus2   2      31m
fs2021-hv0eu-infra-eastus23-qf4kc    Running   Standard_D4s_v3   eastus2   3      31m
fs2021-hv0eu-master-0                Running   Standard_D8s_v3   eastus2   1      37m
fs2021-hv0eu-master-1                Running   Standard_D8s_v3   eastus2   2      37m
fs2021-hv0eu-master-2                Running   Standard_D8s_v3   eastus2   3      37m
fs2021-hv0eu-worker-eastus21-bw8nq   Running   Standard_D8s_v3   eastus2   1      31m
fs2021-hv0eu-worker-eastus22-rtwwh   Running   Standard_D8s_v3   eastus2   2      31m
fs2021-hv0eu-worker-eastus23-tsw44   Running   Standard_D8s_v3   eastus2   3      31m
```

The infra nodes host the router/ingress pods, all the monitoring infrastrucutre, and the image registry.

## Connect to the Openshift container plateform console
```bash
$ oc whoami --show-console
https://console-openshift-console.apps.ocp4.openshift.lcbo.com
```

To login to the console, you need to provide the `kubeadmin` creds. 
Find the password in the installer directory:

```bash
    $ cd YOUR_PROJECT_DIRECTORY
    $ cat installer-files/auth/kubeadmin- 
```

## Upgrade Openshift version
### 1st Step: Backing up etcd data

```bash
    # Start a degug session for a master node (COnnect to a master node, just one single master node not all)
    $ oc debug node/<node_name>
    $ chroot /host
    # Run the cluster-backup.sh script 
    $ /usr/local/bin/cluster-backup.sh /home/core/assets/backup
```
The output run in master node shows we saved 2 files: `snapshot_<datetimestamp>.db` (etcd snapshot) and `static_kuberesources_<datetimestamp>.tar.gz` files that contains resources for the statics pods.

### 2nd Step: Update OCP cluster

- Note your current version
```bash
    $oc get clusterversion
    NAME      VERSION   AVAILABLE   PROGRESSING   SINCE   STATUS
    version   4.6.13     True        False        7h48m    Cluster version is 4.6.13
```

- Review the current update channel information and confirm that your channel is set to stable
```bash
    $oc get clusterversion -o json|jq ".items[0].spec"
    {
        "channel": "stable-4.6",
        "clusterID": "50eba32e-3b1a-474b-a562-2325b9e5ef50",
        "upstream": "https://api.openshift.com/api/upgrades_info/v1/graph"
    }
```

- Identify the available updates
```bash
    $oc adm upgrade
    Cluster version is 4.6.13

    Updates:

    VERSION IMAGE
    4.6.15  quay.io/openshift-release-dev/ocp-release@sha256:b70f550e3fa94af2f7d60a3437ec0275194db36f2dc49991da2336fe21e2824c
    4.6.16  quay.io/openshift-release-dev/ocp-release@sha256:3e855ad88f46ad1b7f56c312f078ca6adaba623c5d4b360143f9f82d2f349741
    .
    .
    .
    4.6.56  quay.io/openshift-release-dev/ocp-release@sha256:ebe1db9c641da831e5efdaaddb895477d80e028f338c4724e03df89a5d0ca4cc
```

- Update to the latest version
```bash
    $oc adm upgrade --to-latest=true 
```

- Update to a specific version
```bash
    $oc adm upgrade --to=<version> 
```

- Review the status the updated version
```bash
    $oc get clusterversion -o json|jq ".items[0].spec" 
```
