variable "auth_token" {
  type        = string
  description = "Packet API Key"
}

variable "project_id" {
  type        = string
  description = "The project id to deploy into"
}

variable "ipsec_peer_public_ip" {
  type        = string
  description = "Public IP of the router you're creating the VPN with"
}

variable "hostname" {
  type        = string
  default     = "edge-router"
  description = "Hostname for router"
}

variable "facility" {
  type        = string
  default     = "iad2"
  description = "Packet Facility to deploy into"
}

variable "plan" {
  type        = string
  default     = "c2.medium.x86"
  description = "Packet device type to deploy"
}

variable "operating_system" {
  type        = string
  description = "The Operating system of the node (This needs to be (custom_ipxe)"
  default     = "custom_ipxe"
}

variable "ipxe_script_url" {
  type        = string
  default     = "http://s3.codyhill.co/vyos122.ipxe"
  description = "Location of VyOS iPXE script"
}

variable "always_pxe" {
  type        = bool
  default     = false
  description = "Wheather to always boot via iPXE or not."
}

variable "billing_cycle" {
  description = "How the node will be billed (Not usually changed)"
  default     = "hourly"
}

variable "bgp_local_asn" {
  type        = number
  default     = 65000
  description = "Local BGP ASN"
}

variable "bgp_neighbor_asn" {
  type        = number
  default     = 65100
  description = "Neighbor BGP ASN"
}

variable "ipsec_private_cidr" {
  type        = string
  default     = "169.254.254.252/30"
  description = "IPSec IPs used for BGP peering (/30 usually)"
}

variable "neighbor_short_name" {
  type        = string
  default     = "Equinix"
  description = "Friendly name of who you are peering with"
}

variable "private_net_cidr" {
  type        = string
  default     = "172.31.254.0/24"
  description = "Private IP Space used for Packet Devices that will be advertized via BGP (/30 or greater)"
}

variable "public_dns_1_ip" {
  type        = string
  default     = "8.8.8.8"
  description = "Public DNS Name Server 1"
}

variable "public_dns_2_ip" {
  type        = string
  default     = "8.8.4.4"
  description = "Public DNS Name Server 2"
}
