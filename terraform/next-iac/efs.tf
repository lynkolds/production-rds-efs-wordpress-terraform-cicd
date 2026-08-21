# EFS is restored from an AWS Backup recovery point.
# After the restore is complete, import the restored EFS file system
# into Terraform state using:
#
# terraform import aws_efs_file_system.efs_file_system fs-xxxxxxxxxxxxxxxxx
#
# Terraform will then manage the restored EFS, create mount targets,
# and manage future EFS configuration changes.

resource "aws_efs_file_system" "efs_file_system" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-efs"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_az1" {
  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = aws_subnet.private_app_subnet_az1.id
  security_groups = [aws_security_group.efs_security_group.id]
}

resource "aws_efs_mount_target" "efs_mount_target_az2" {
  file_system_id  = aws_efs_file_system.efs_file_system.id
  subnet_id       = aws_subnet.private_app_subnet_az2.id
  security_groups = [aws_security_group.efs_security_group.id]
}