variable "environment" {
  description = "Label to be used for tags and resource names for identification"
  default     = "default"
}

variable "zcompute_api" {
  type        = string
  description = "IP/DNS of the zCompute cluster API endpoint"
}

variable "secondary_zcompute_api" {
  type        = string
  description = "IP/DNS of the second zCompute cluster API endpoint"
}

variable "primary_k8s_ami_id" {
  description = "ID (in AWS format) of the AMI to be used for the kubernetes nodes"
}

variable "secondary_k8s_ami_id" {
  description = "ID (in AWS format) of the AMI to be used for the kubernetes nodes"
}

variable "k8s_master_volume_size" {
  type = string
}

variable "k8s_worker_volume_size" {
  type = string
}

variable "k8s_masters_count" {
  type = number
}

variable "primary_k8s_workers_count" {
  type = number
}

variable "secondary_k8s_workers_count" {
  type = number
}

variable "k8s_master_instance_type" {
  default     = "z4.xlarge"
  description = "K8s server (master) node instance type"
}

variable "k8s_worker_instance_type" {
  default     = "z4.xlarge"
  description = "K8s agent (worker) node instance type"
}

variable "taint_masters" {
  default     = true
  type        = bool
  description = "If set to false, user workloads would run on K8s master nodes"
}

variable "k8s_cni" {
  type        = string
  default     = "calico"
  description = "CNI options that rancher supports"

  validation {
    condition     = contains(["calico", "canal", "flannel"], var.k8s_cni)
    error_message = "Valid values for var: cni are (calico, canal, flannel)."
  }
}

variable "primary_vpc_id" {
  type = string
}

variable "primary_private_subnets_ids" {
  type = list(string)
}

variable "primary_public_subnets_ids" {
  type = list(string)
}

variable "secondary_private_subnets_ids" {
  type = list(string)
}

variable "primary_security_groups_ids" {
  type = list(string)
}

variable "secondary_security_groups_ids" {
  type = list(string)
}

variable "primary_worker_key_pair" {
  type = string
}

variable "master_key_pair" {
  type = string
}

variable "secondary_worker_key_pair" {
  type = string
}

variable "master_load_balancer_id" {
  type = string
}

variable "master_load_balancer_public_ip" {
  type    = string
  default = ""
}

variable "master_load_balancer_private_ip" {
  type    = string
  default = ""
}

variable "master_load_balancer_internal_dns" {
  type    = string
  default = ""
}

variable "k8s_api_server_port" {
  type = number
}

variable "primary_cluster_access_key" {
  type      = string
  sensitive = true
}

variable "primary_cluster_access_secret_id" {
  type      = string
  sensitive = true
}

variable "secondary_cluster_access_key" {
  type      = string
  sensitive = true
}

variable "secondary_cluster_access_secret_id" {
  type      = string
  sensitive = true
}

