terraform {
  required_version = ">= 1.0"

  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = "~> 1.14"
    }
  }
  provider_meta "equinix" {
    module_name = "equinix-vyos-router"
  }
}
