resource "random_uuid" "unique_id" {
}

resource "ibm_resource_instance" "portworx" {
  count             = var.classic_infra ? 0 : 1
  name              = "portworx-service-${split("-", random_uuid.unique_id.result)[0]}"
  service           = "portworx"
  plan              = var.pwx_plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id

  tags = [
    "clusterid:${data.ibm_container_vpc_cluster.cluster[0].id}",
    "managed_by:terraform",
    "cluster_name:${data.ibm_container_vpc_cluster.cluster[0].name}",
    "owner:sudas"
  ]
  //TODO: Recheck Tags

  parameters = {
    apikey                    = var.ibmcloud_api_key
    cluster_name              = var.cluster_name
    clusters                  = var.cluster_name
    etcd_endpoint             = var.use_external_etcd ? var.external_etcd_connection_url : null
    etcd_secret               = var.use_external_etcd ? var.etcd_secret_name : null
    internal_kvdb             = var.use_external_etcd ? "external" : "internal"
    image_version             = "2.11.0"
    secret_type               = var.secret_type
    cloud_drive               = var.use_cloud_drives ? "Yes" : "No"
    max_storage_node_per_zone = var.max_storage_node_per_zone
    num_cloud_drives          = var.num_cloud_drives
    size                      = element(var.cloud_drives_sizes, 0)
    size2                     = (var.num_cloud_drives == 2) ? element(var.cloud_drives_sizes, 1) : 0
    size3                     = (var.num_cloud_drives == 3) ? element(var.cloud_drives_sizes, 2) : 0
    storageClassName          = element(var.storage_classes, 0)
    storageClassName2         = (var.num_cloud_drives == 2) ? element(var.storage_classes, 1) : ""
    storageClassName3         = (var.num_cloud_drives == 3) ? element(var.storage_classes, 2) : ""
    csi                       = var.csi ? "True" : "False"
    //TODO: fix csi boolean issue
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/utils/"
    command     = "/bin/bash portworx_wait_until_ready.sh"
  }
}




resource "ibm_resource_instance" "portworx_on_classic" {
  count             = var.classic_infra ? 1 : 0
  name              = "portworx-service-${split("-", random_uuid.unique_id.result)[0]}"
  service           = "portworx"
  plan              = var.pwx_plan
  location          = var.region
  resource_group_id = data.ibm_resource_group.group.id

  tags = [
    "clusterid:${data.ibm_container_cluster.cluster_classic[0].id}",
    "managed_by:terraform",
    "cluster_name:${data.ibm_container_cluster.cluster_classic[0].name}",
    "owner:sudas"
  ]
  //TODO: Recheck Tags

  parameters = {
    apikey                    = var.ibmcloud_api_key
    cluster_name              = var.cluster_name
    clusters                  = var.cluster_name
    etcd_endpoint             = var.use_external_etcd ? var.external_etcd_connection_url : null
    etcd_secret               = var.use_external_etcd ? var.etcd_secret_name : null
    internal_kvdb             = var.use_external_etcd ? "external" : "internal"
    image_version             = "2.11.0"
    secret_type               = var.secret_type
    csi                       = var.csi ? "True" : "False"
    //TODO: fix csi boolean issue
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/utils/"
    command     = "/bin/bash portworx_wait_until_ready.sh"
  }
}




resource "null_resource" "portworx_destroy" {
  provisioner "local-exec" {
    when        = destroy
    working_dir = "${path.module}/utils/"
    command     = "/bin/bash portworx_destroy.sh"
  }
}
