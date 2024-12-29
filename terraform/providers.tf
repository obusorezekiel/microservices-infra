provider "aws" {
  region = "us-east-1"
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.17.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  required_version = "~> 1.0"
}


