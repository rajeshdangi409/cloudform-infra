variable "aws_region" {
  description = "Specify AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
}

variable "eks_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
}

variable "project_name" {
  description = "Project name used for AWS resource tagging"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the VPC"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
}

variable "rds_security_group_name" {
  description = "Name of the RDS security group"
  type        = string
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "rds_engine_version" {
  description = "MySQL engine version for RDS"
  type        = string
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "rds_database_name" {
  description = "RDS database name"
  type        = string
}