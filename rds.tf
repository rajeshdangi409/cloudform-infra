resource "aws_security_group" "rds" {
  name        = var.rds_security_group_name
  description = "Security group for Flask RDS"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = var.rds_security_group_name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = module.eks.node_security_group_id

  ip_protocol = "tcp"
  from_port   = 3306
  to_port     = 3306
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = var.rds_identifier

  engine         = "mysql"
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  allocated_storage     = 20
  max_allocated_storage = 1000
  storage_type          = "gp2"

  storage_encrypted = true

  db_name  = var.rds_database_name
  username = "admin"
  password = var.db_password

  manage_master_user_password = false

  port = 3306

  multi_az = false

  publicly_accessible = false

  subnet_ids = module.vpc.private_subnets

  create_db_subnet_group = true

  create_db_parameter_group = false
  create_db_option_group    = false

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  backup_retention_period = 1

  deletion_protection = false
  skip_final_snapshot = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}