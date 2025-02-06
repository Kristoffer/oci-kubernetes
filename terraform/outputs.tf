output "k8s-cluster-id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}
output "asdf" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}

output "public_subnet_id" {
  value = oci_core_subnet.vcn_public_subnet.id
}
output "node_pool_id" {
  value = oci_containerengine_node_pool.k8s_node_pool.id
}
