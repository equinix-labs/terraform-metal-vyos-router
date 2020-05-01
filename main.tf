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
  special = false
}

resource "random_string" "login_password" {
  length = 20
  min_upper = 2
  min_lower = 2
  min_numeric = 2
  special = false
}

resource "tls_private_key" "ssh_key_pair" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "packet_ssh_key" "ssh_pub_key" {
    name = "VyOS SSH Key"
    public_key = chomp(tls_private_key.ssh_key_pair.public_key_openssh)
}


data "template_file" "user_data" {
    template = file("templates/user_data.conf")
}

resource "packet_device" "router" {
    depends_on = [
        packet_ssh_key.ssh_pub_key
    ]
    hostname         = var.hostname
    plan             = var.plan
    facilities       = [var.facility]
    operating_system = var.operating_system
    billing_cycle    = var.billing_cycle
    project_id       = var.project_id
    ipxe_script_url  = var.ipxe_script_url
    always_pxe       = var.always_pxe
    network_type     = "hybrid"
    user_data        = data.template_file.user_data.rendered
}

resource "packet_port_vlan_attachment" "router_vlan_attach" {
    device_id = packet_device.router.id
    port_name = "eth1"
    vlan_vnid = packet_vlan.private_vlan.vxlan
}

data "template_file" "vyos_config" {
    template = file("templates/config.boot")
    vars = {
        bgp_local_asn = var.bgp_local_asn
        bgp_neighbor_asn = var.bgp_neighbor_asn
        bgp_password = random_string.bgp_password.result
        hostname = var.hostname
        ipsec_psk = random_string.ipsec_psk.result
        ipsec_peer_public_ip = var.ipsec_peer_public_ip
        ipsec_peer_private_ip = cidrhost(var.ipsec_private_cidr, 2)
        ipsec_private_ip_cidr = format("%s/%s", cidrhost(var.ipsec_private_cidr, 2), split("/", var.ipsec_private_cidr)[1])
        login_password = random_string.login_password.result
        neighbor_short_name = var.neighbor_short_name
        private_net_cidr = var.private_net_cidr
        private_net_dhcp_start_ip = cidrhost(var.private_net_cidr, 2)
        private_net_dhcp_stop_ip = cidrhost(var.private_net_cidr, -2)
        private_net_gateway_ip_cidr = format("%s/%s", cidrhost(var.private_net_cidr, 1), split("/", var.private_net_cidr)[1])
        private_net_gateway_ip = cidrhost(var.private_net_cidr, 1)
        public_dns_1_ip = var.public_dns_1_ip
        public_dns_2_ip = var.public_dns_2_ip
        router_ipv6_gateway_ip = packet_device.router.network.1.gateway
        router_ipv6_ip_cidr = format("%s/%s", packet_device.router.network.1.address, packet_device.router.network.1.cidr)
        router_private_cidr = format("%s/%s", cidrhost(format("%s/%s", packet_device.router.network.2.address, packet_device.router.network.2.cidr), 0), packet_device.router.network.2.cidr)
        router_private_gateway_ip = packet_device.router.network.2.gateway
        router_private_ip_cidr = format("%s/%s", packet_device.router.network.2.address, packet_device.router.network.2.cidr)
        router_public_gateway_ip = packet_device.router.network.0.gateway
        router_public_ip_cidr = format("%s/%s", packet_device.router.network.0.address, packet_device.router.network.0.cidr)
        router_public_ip = packet_device.router.network.0.address
    }
}

resource "null_resource" "configure_vyos"{
    connection {
        type = "ssh"
        user = "vyos"
        private_key = chomp(tls_private_key.ssh_key_pair.private_key_pem)
        host = packet_device.router.access_public_ipv4
    }

    provisioner "file" {
        content = data.template_file.vyos_config.rendered
        destination = "/tmp/config.boot"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/config.boot /config/config.boot",
            "sudo chmod 775 /config/config.boot",
            "sudo chown root:vyattacfg /config/config.boot",
            "#sudo sudo apt remove cloud-init -y",
            "#sudo rm -f /etc/network/interfaces.d/50-cloud-init.cfg",
            "sudo /sbin/shutdown -r 1"
        ]
    }
}

output "SSH" {
  value       = "ssh vyos@${packet_device.router.network.0.address}"
  description = "Command to SSH into the VyOS Router"
}

output "Out_of_Band_Console" {
  value       = "ssh ${packet_device.router.id}@sos.${lower(var.facility)}.packet.net"
  description = "Command to SSH into the Serial over Lan Console of the VyOS Router"
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

