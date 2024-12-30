module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.16.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.0"

  cluster_name                             = local.name
  cluster_version                          = "1.30"
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.medium", "t2.micro"]

    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    ezekiel-cluster-wg = {
      min_size     = 1
      max_size     = 2
      desired_size = 2

      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      tags = {
        ExtraTag = "helloworld"
      }
    }
  }

  tags = local.tags
}

# Trigger Ansible provisioning
resource "null_resource" "ansible_provisioner" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      aws eks update-kubeconfig --name ${local.name} --region us-east-1 && \
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i ../ansible/inventory.yml \
        --extra-vars "cluster_name=${local.name}" \
        ../ansible/site.yml
    EOT
  }
}
