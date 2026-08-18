module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 3.0"

  repository_name = var.ecr_repository_name

  repository_force_delete = true

  repository_image_tag_mutability = "MUTABLE"

  repository_image_scan_on_push = true

  create_lifecycle_policy = false
}