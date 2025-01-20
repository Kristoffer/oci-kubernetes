provider "oci" {
  region = var.region
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.6.0"

  compartment_id = var.compartment_id
  region         = var.region

  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null

  enable_ipv6 = true


  vcn_name = "kubernetes-vcn"
  #vcn_dns_label = "kubernetes"
  #vcn_cidrs     = ["10.0.0.0/16"]

  create_internet_gateway = false
  create_nat_gateway      = false
  create_service_gateway  = false
}
