firewall {
    all-ping enable
    broadcast-ping disable
    config-trap disable
    ipv6-receive-redirects disable
    ipv6-src-route disable
    ip-src-route disable
    log-martians enable
    name OUTSIDE-IN {
        default-action drop
        rule 10 {
            action accept
            state {
                established enable
                related enable
            }
        }
    }
    receive-redirects disable
    send-redirects enable
    source-validation disable
    syn-cookies enable
    twa-hazards-protection disable
}
interfaces {
    bonding bond0 {
        address ${router_public_ip_cidr}
        address ${router_private_ip_cidr}
        address ${router_ipv6_ip_cidr}
        description "Bond towards Packet"
        firewall {
            in {
                name OUTSIDE-IN
            }
        }
        hash-policy layer2
        mode 802.3ad
    }
    ethernet eth0 {
        bond-group bond0
        description "member of bond0"
        duplex auto
        smp-affinity auto
        speed auto
    }
    ethernet eth1 {
        address ${private_net_gateway_ip_cidr}
        description "Private Net"
        duplex auto
        smp-affinity auto
        speed auto
    }
    loopback lo {
    }
    vti vti1 {
        address ${ipsec_private_ip_cidr}
    }
}
nat {
    source {
        rule 100 {
            outbound-interface bond0
            source {
                address ${private_net_cidr}
            }
            translation {
                address masquerade
            }
        }
    }
}
policy {
    prefix-list TO-${neighbor_short_name} {
        rule 10 {
            action permit
            prefix ${private_net_cidr}
        }
    }
    route-map ${neighbor_short_name}-OUT {
        rule 10 {
            action permit
            match {
                ip {
                    address {
                        prefix-list TO-${neighbor_short_name}
                    }
                }
            }
        }
        rule 20 {
            action deny
        }
    }
}
protocols {
    bgp ${bgp_local_asn} {
        address-family {
            ipv4-unicast {
                network ${private_net_cidr} {
                }
            }
        }
        neighbor ${ipsec_peer_private_ip} {
            address-family {
                ipv4-unicast {
                    route-map {
                        export ${neighbor_short_name}-OUT
                    }
                    soft-reconfiguration {
                        inbound
                    }
                }
            }
            password ${bgp_password}
            remote-as ${bgp_neighbor_asn}
            timers {
                holdtime 30
                keepalive 10
            }
        }
        parameters {
            log-neighbor-changes
        }
        timers {
            holdtime 4
            keepalive 2
        }
    }
    static {
        route 0.0.0.0/0 {
            next-hop ${router_public_gateway_ip} {
            }
        }
        route ${router_private_cidr} {
            next-hop ${router_private_gateway_ip} {
            }
        }
        route6 ::/0 {
            next-hop ${router_ipv6_gateway_ip} {
            }
        }
    }
}
service {
    dhcp-server {
        shared-network-name lan-dhcp {
            authoritative
            subnet ${private_net_cidr} {
                default-router ${private_net_gateway_ip}
                dns-server ${private_net_gateway_ip}
                lease 86400
                range 0 {
                    start ${private_net_dhcp_start_ip}
                    stop ${private_net_dhcp_stop_ip}
                }
            }
        }
    }
    dns {
        forwarding {
            listen-address ${private_net_gateway_ip}
            name-server ${public_dns_1_ip}
            name-server ${public_dns_2_ip}
        }
    }
    ssh {
        client-keepalive-interval 180
        port 22
    }
}
system {
    config-management {
        commit-revisions 100
    }
    console {
        device ttyS0 {
            speed 9600
        }
        device ttyS1 {
            speed 115200
        }
    }
    host-name ${hostname}
    login {
        user vyos {
            authentication {
                plaintext-password "${login_password}"
            }
            level admin
        }
    }
    name-server ${public_dns_1_ip}
    name-server ${public_dns_2_ip}
    ntp {
        server 0.pool.ntp.org {
        }
        server 1.pool.ntp.org {
        }
        server 2.pool.ntp.org {
        }
    }
    syslog {
        global {
            facility all {
                level info
            }
            facility protocols {
                level debug
            }
        }
    }
    time-zone UTC
}
vpn {
    ipsec {
        esp-group ${neighbor_short_name}-S2S-IPSEC {
            compression disable
            lifetime 3600
            mode tunnel
            pfs dh-group2
            proposal 1 {
                encryption aes128
                hash sha1
            }
        }
        ike-group ${neighbor_short_name}-S2S-IKE {
            dead-peer-detection {
                action restart
                interval 15
                timeout 30
            }
            ikev2-reauth no
            key-exchange ikev1
            lifetime 3600
            proposal 1 {
                dh-group 2
                encryption aes128
                hash md5
            }
        }
        ipsec-interfaces {
            interface bond0
        }
        site-to-site {
            peer ${ipsec_peer_public_ip} {
                authentication {
                    mode pre-shared-secret
                    pre-shared-secret ${ipsec_psk}
                }
                connection-type initiate
                ike-group ${neighbor_short_name}-S2S-IKE
                ikev2-reauth inherit
                local-address ${router_public_ip}
                vti {
                    bind vti1
                    esp-group ${neighbor_short_name}-S2S-IPSEC
                }
            }
        }
    }
}


/* Warning: Do not remove the following line. */
/* === vyatta-config-version: "broadcast-relay@1:cluster@1:config-management@1:conntrack-sync@1:conntrack@1:dhcp-relay@2:dhcp-server@5:firewall@5:ipsec@5:l2tp@1:mdns@1:nat@4:ntp@1:pptp@1:qos@1:quagga@3:ssh@1:system@9:vrrp@2:vyos-accel-ppp@1:wanloadbalance@3:webgui@1:webproxy@1:webproxy@2:zone-policy@1" === */
/* Release version: 1.2.2 */