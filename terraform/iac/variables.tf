# Global variables
variable "region" {
  description = "AWS region to deploy resources in"
}

variable "project_name" {
  description = "Project name used in resource names"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
}

# VPC networking
variable "vpc_cidr" {}

variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}

variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}

variable "private_data_subnet_az1_cidr" {}
variable "private_data_subnet_az2_cidr" {}


# Database (RDS)
variable "database_snapshot_identifier" {}
variable "database_instance_class" {}
variable "database_instance_identifier" {}
variable "multi_az_deployment" {}

variable "rds_master_password" {
  type        = string
  description = "RDS master password"
  sensitive   = true
}

# ALB
variable "target_type" {}
variable "certificate_arn" {}

# Route53
variable "domain_name" {}
variable "record_name" {}

# name of existing IAM role and instance profile for ec2 instances in the ASG to use SSM
#variable "wordpress_ec2_iam_role_name" {}
#variable "wordpress_ec2_instance_profile_name" {}

# Auto Scaling Group
#variable "wordpress_ami_id" {}
#variable "instance_type" {}
#variable "asg_min_size" {}
#variable "asg_desired_capacity" {}
#variable "asg_max_size" {}
#variable "sns_email_endpoint" {}
