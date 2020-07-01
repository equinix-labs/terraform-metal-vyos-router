output "SSH" {
  value       = "ssh vyos@${packet_device.router.network.0.address}"
  description = "Command to SSH into the VyOS Router"
}

output "Out_of_Band_Console" {
  value       = "ssh ${packet_device.router.id}@sos.${lower(var.facility)}.packet.net"
  description = "Command to SSH into the Serial over Lan Console of the VyOS Router"
}

output "VyOS_Config_File" {
  value       = "${path.module}/vyos.conf"
  description = "The Name of the VyOS config file"
}

output "BGP_Password" {
  value       = random_string.bgp_password.result
  description = "The BGP password for peering"
}

output "IPSec_Pre_Shared_Key" {
  value       = random_string.ipsec_psk.result
  description = "IPSec pre shared key for authentication."
}

output "IPSec_Public_IP" {
  value       = packet_device.router.network.0.address
  description = "Public IP for IPSec VPN"
}

output "IPSec_Private_IP_CIDR" {
  value       = format("%s/%s", cidrhost(var.ipsec_private_cidr, 2), split("/", var.ipsec_private_cidr)[1])
  description = "Private IP space inside the ipsec tunnel to do BGP peering."
}
