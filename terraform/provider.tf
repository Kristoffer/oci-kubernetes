provider "oci" {
  region              = var.region
  config_file_profile = "DEFAULT"
}


terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket                      = "oci-kubernetes-state"
    region                      = "eu-stockholm-1"
    key                         = "tf.tfstate"
    profile                     = "oci-kubernetes"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    use_path_style              = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    endpoints = {
      s3 = "https://axgmifjtanz5.compat.objectstorage.eu-stockholm-1.oraclecloud.com"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/oci-config"
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}
