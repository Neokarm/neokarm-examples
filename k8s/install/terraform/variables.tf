
variable "environment" {
  description = "Label to be used for tags and resource names for identification"
  default = "rke"
}

variable "zcloud_zone" {
  description = "Domain of the zCompute cluster - {zcloud_hostname}.{zcloud_zone} should match the cluster certificate"
  default = "zadara.net"
}
variable "zcloud_hostname" {
  description = "Hostname of the zCompute cluster - {zcloud_hostname} should match the cluster certificate"
  default = "zcompute.cloud.zadara.net"
}
variable "zcompute_api_ip" {
  description = "IP of the zCompute cluster API endpoint"
}

variable "ssh_key_file" {
  description = "SSH public key file for kubernetes node SSH access"
}
variable "ssh_private_key_file" { 
  description = "SSH private key file for kubernetes node SSH access" 
}

variable "rke_servers_count" {
  type = number
  default = 3
}
variable "rke_agents_count" {
  type = number
  default = 3
}

variable "ami_id" {
  description = "ID (in AWS format) of the AMI to be used for the kubernetes nodes"
}

variable "use_route53_for_cluster_dns_resolution" {
  description = "Create the cluster in the VPC Private zone"
  default = false
}

variable "rke_version" {
  default = "v1.21.5~rke2r1"
}

variable "server_instance_type" {
  default = "z4.xlarge"
  description = "K8s server (master) node instance type"
}

variable "agent_instance_type" {
  default = "z4.2xlarge"
  description = "K8s agent (worker) node instance type"
}

variable "taint_servers" {
  default = true
  type = bool
  description = "If set to false, user workloads would run on K8s master nodes"
}