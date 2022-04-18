variable "environment" {
  description = "Label to be used for tags and resource names for identification"
  default     = "default"
}

variable "zcompute_api" {
  type        = string
  description = "IP/DNS of the zCompute cluster API endpoint"
}

variable "ssh_public_key_file_path" {
  description = "SSH public key file for kubernetes node SSH access"
}
variable "ssh_key_file_path" {
  description = "SSH private key file for kubernetes node SSH access"
}

variable "rke_servers_count" {
  type    = number
  default = 3
}
variable "rke_agents_count" {
  type    = number
  default = 3
}

variable "rke2_ami_id" {
  description = "ID (in AWS format) of the AMI to be used for the kubernetes nodes"
}

variable "bastion_ami_id" {
  description = "ID (in AWS format) of the AMI to be used for the bastion host"
}

variable "server_instance_type" {
  default     = "z4.xlarge"
  description = "K8s server (master) node instance type"
}

variable "agent_instance_type" {
  default     = "z4.2xlarge"
  description = "K8s agent (worker) node instance type"
}

variable "taint_servers" {
  default     = true
  type        = bool
  description = "If set to false, user workloads would run on K8s master nodes"
}

variable "cni" {
  type        = string
  default     = "calico"
  description = "CNI options that rancher supports"

  validation {
    condition     = contains(["calico", "canal", "flannel"], var.cni)
    error_message = "Valid values for var: cni are (calico, canal, flannel)."
  }
}

variable "bgp_enabled" {
  default     = false
  type        = bool
  description = "Activate Calico bgp piering"
}

variable "calico_cidr" {
  default     = "10.42.0.0/16"
  description = "cidr for initial calico ippool"
}

variable "bastion_username" {
  type        = string
  description = "bastion user name for ssh"
}

variable "node_username" {
  type        = string
  description = "RKE2 node user name for ssh"
}

variable "bastion_instance_type" {
  type        = string
  default     = "t2.micro"
  description = "The builder instance type"
}

variable "install_custom_ca_certificate" {
  type        = bool
  default     = false
  description = "Use custom CA certificate in old linux release for the EBS driver"
}

variable "custom_ca_certificate_path" {
  type        = string
  default     = "ca.crt"
  description = "Custom CA certificate file path"
}