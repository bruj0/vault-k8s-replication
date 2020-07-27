locals {
  cluster_type = "private"
}

provider "google" {
  version = "~> 3.16.0"
  region  = var.region
}

data "google_compute_subnetwork" "subnetwork" {
  name    = var.subnetwork
  project = var.project_id
  region  = var.region
}

module "gke" {
  source                    = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                   = "v10.0.0"
  project_id                = var.project_id
  name                      = "${local.cluster_type}-${var.cluster_name_suffix}"
  regional                  = true
  region                    = var.region
  network                   = var.network
  subnetwork                = var.subnetwork
  ip_range_pods             = var.ip_range_pods
  ip_range_services         = var.ip_range_services
  create_service_account    = true
  service_account           = var.compute_engine_service_account
  enable_private_endpoint   = true
  enable_private_nodes      = true
  master_ipv4_cidr_block    = "172.16.0.0/28"
  default_max_pods_per_node = 20
  remove_default_node_pool  = true

  node_pools = [
    {
      name               = "pool-01"
      machine_type       = "n1-standard-4"
      min_count          = 1
      max_count          = 100
      local_ssd_count    = 0
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.compute_engine_service_account
      preemptible        = true
      max_pods_per_node  = 100
      initial_node_count = 3
    },
  ]

  master_authorized_networks = [
    {
      cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
      display_name = "VPC"
    },
  ]
}

data "google_client_config" "default" {
}