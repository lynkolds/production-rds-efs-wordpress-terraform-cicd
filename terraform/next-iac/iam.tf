# Existing AWS IAM role used by AWS Backup for EFS backups
data "aws_iam_role" "aws_backup_role" {
  name = "AWSBackupDefaultServiceRole"
}

# Existing IAM role used by WordPress EC2 instances to access parameter store
data "aws_iam_role" "wordpress_ec2_role" {
  name = var.wordpress_ec2_iam_role_name
}

# Existing instance profile associated with the WordPress EC2 IAM role
data "aws_iam_instance_profile" "wordpress_ec2_instance_profile" {
  name = var.wordpress_ec2_instance_profile_name
}
