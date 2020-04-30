provider "packet" {
    auth_token = var.auth_token
}

resource "packet_vlan" "private_vlan" {
    facility    = var.facility
    project_id  = var.project_id
    description = "Private Network"
}

resource "random_string" "bgp_password" {
    length = 18
    min_upper = 1 
    min_lower = 1 
    min_numeric = 1 
    special = false
}

resource "random_string" "ipsec_psk" {
  length = 20
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  min_special = 2
  override_special = "$!?@*"
}

resource "packet_device" "router" {
    hostname         = var.hostname
    plan             = var.plan
    facilities       = [var.facility]
    operating_system = var.operating_system
    billing_cycle    = var.billing_cycle
    project_id       = var.project_id
    ipxe_script_url  = var.ipxe_script_url
    always_pxe       = var.always_pxe
    network_type     = "hybrid"
}

resource "packet_port_vlan_attachment" "router_vlan_attach" {
    device_id = packet_device.router.id
    port_name = "eth1"
    vlan_vnid = packet_vlan.private_vlan.vxlan
}

data "template_file" "vyos_config" {
    template = file("templates/vyos_config.conf")
    vars = {
        bgp_local_asn = var.bgp_local_asn
        bgp_neighbor_asn = var.bgp_neighbor_asn
        bgp_password = random_string.bgp_password.result
        hostname = var.hostname
        ipsec_psk = random_string.ipsec_psk.result
        ipsec_peer_public_ip = var.ipsec_peer_public_ip
        ipsec_peer_private_ip = cidrhost(var.ipsec_private_cidr, 2)
        ipsec_private_ip_cidr = format("%s/%s", cidrhost(var.ipsec_private_cidr, 2), split("/", var.ipsec_private_cidr)[1])
        neighbor_short_name = var.neighbor_short_name
        private_net_cidr = var.private_net_cidr
        private_net_dhcp_start_ip = cidrhost(var.private_net_cidr, 2)
        private_net_dhcp_stop_ip = cidrhost(var.private_net_cidr, -2)
        private_net_gateway_ip_cidr = format("%s/%s", cidrhost(var.private_net_cidr, 1), split("/", var.private_net_cidr)[1])
        private_net_gateway_ip = cidrhost(var.private_net_cidr, 2)
        public_dns_1_ip = var.public_dns_1_ip
        public_dns_2_ip = var.public_dns_2_ip
        router_ipv6_gateway_ip = packet_device.router.network.1.gateway
        router_ipv6_ip_cidr = format("%s/%s", packet_device.router.network.1.address, packet_device.router.network.1.cidr)
        router_private_cidr = format("%s/%s", cidrhost(format("%s/%s", packet_device.router.network.2.address, packet_device.router.network.2.cidr), 0), packet_device.router.network.2.cidr)
        router_private_gateway_ip = packet_device.router.network.2.gateway
        router_private_ip_cidr = format("%s/%s", packet_device.router.network.2.address, packet_device.router.network.2.cidr)
        router_public_gateway_ip = packet_device.router.network.0.gateway
        router_public_ip_cidr = format("%s/%s", packet_device.router.network.1.address, packet_device.router.network.1.cidr)
        router_public_ip = packet_device.router.network.0.address
    }
}

resource "local_file" "vyos_config" {
    content     = data.template_file.vyos_config.rendered
    filename = "${path.module}/vyos.conf"
}

output "SSH" {
  value       = "ssh vyos@${packet_device.router.network.0.address}"
  description = "Command to SSH into the VyOS Router"
}

output "Out_of_Band_Console" {
  value       = "ssh ${packet_device.router.id}@sos.${lower(var.facility)}.packet.net"
  description = "Command to SSH into the Serial over Lan Console of the VyOS Router"
}