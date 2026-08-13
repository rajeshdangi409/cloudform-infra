module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "flask-eks-rds"
  kubernetes_version = "1.33"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true

  endpoint_public_access = true

  addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }

    coredns = {
      most_recent = true
    }

    kube-proxy = {
      most_recent = true
    }

    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    general = {
      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 2
    }
  }

  tags = {
    Project     = "flask-eks-rds"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
