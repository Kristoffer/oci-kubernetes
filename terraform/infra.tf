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

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
}

// ...previous things are omitted for simplicity

resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.31.1"
  name               = "k8s-cluster"
  vcn_id             = module.vcn.vcn_id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
} // ...previous things are omitted for simplicity

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

// ...previous things are omitted for simplicity

resource "oci_containerengine_node_pool" "k8s_node_pool" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id     = var.compartment_id
  kubernetes_version = "v1.31.1"
  name               = "k8s-node-pool"
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.vcn_private_subnet.id
    }
    size = 2


  }
  node_shape = "VM.Standard.A1.Flex"

  node_shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  node_source_details {
    image_id    = "ocid1.image.oc1.eu-stockholm-1.aaaaaaaanosidurjvmhvgzjr6j3qkqouzz2cp3um5q2m5vzlt6mw4ra6tnfq"
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "k8s-cluster"
  }

  ssh_public_key = var.ssh_public_key
}

locals {
  active_nodes = [for node in oci_containerengine_node_pool.k8s_node_pool.nodes : node if node.state == "ACTIVE"]
}

resource "oci_network_load_balancer_network_load_balancer" "nlb" {
  compartment_id = var.compartment_id
  display_name   = "k8s-nlb"
  subnet_id      = oci_core_subnet.vcn_public_subnet.id

  is_private                     = false
  is_preserve_source_destination = false
}

resource "oci_network_load_balancer_backend_set" "nlb_backend_set" {
  health_checker {
    protocol = "TCP"
    port     = 10256
  }
  name                     = "k8s-backend-set"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  policy                   = "FIVE_TUPLE"

  is_preserve_source = false
}

resource "oci_network_load_balancer_backend" "nlb_backend" {
  count                    = length(local.active_nodes)
  backend_set_name         = oci_network_load_balancer_backend_set.nlb_backend_set.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  port                     = 31600
  target_id                = local.active_nodes[count.index].id
}

resource "oci_network_load_balancer_listener" "nlb_listener" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb_backend_set.name
  name                     = "k8s-nlb-listener"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb.id
  port                     = "80"
  protocol                 = "TCP"
}
