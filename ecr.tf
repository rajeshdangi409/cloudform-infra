module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.0"

  repository_name = "flask-eks-rds"

  repository_force_delete = true

  repository_image_tag_mutability = "MUTABLE"

  repository_image_scan_on_push = true

  create_lifecycle_policy = false
}