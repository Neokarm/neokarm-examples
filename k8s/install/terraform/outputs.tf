output "rke_master_loadbalancer_dns" {
  value = aws_lb.rke_master_lb.dns_name
}

output "rke_bastion_eip" {
  value = aws_eip.bastion_eip.public_ip
}

output "rke_server_ips" {
  value = concat([aws_instance.rke_seeder.private_ip], aws_instance.rke_servers[*].private_ip)
}

output "rke_agent_ips" {
  value = aws_instance.rke_agents[*].private_ip
}

output "rke_config_filename" {
  value = "kubeconfig.yaml"
}

output "zcompute_api_fqdn" {
  value = local.zcompute_api_fqdn
  description = "zCompute API DNS from inside the VPC"
}