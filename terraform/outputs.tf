output "k8s-cluster-id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}
output "asdf" {
  value = data.oci_identity_availability_domains.ads.availability_domains
}
