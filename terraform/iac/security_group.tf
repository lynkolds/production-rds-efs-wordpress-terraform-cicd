# create security group for the application load balancer
resource "aws_security_group" "alb_security_group" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "enable http/https access on port 80/443"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# create security group for ec2 instance connect endpoint
resource "aws_security_group" "ec2_instance_connect_endpoint_sg" {
  name        = "${var.project_name}-${var.environment}-ec2-instance-connect-endpoint-sg"
  description = "enable ec2 instance connect endpoint to access ec2 instances in vpcvia port 22"
  vpc_id      = aws_vpc.vpc.id

  egress {
    description = "allow outbound ssh access to ec2 instances in vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
}

# create security group for the app server
resource "aws_security_group" "app_server_security_group" {
  name        = "${var.project_name}-${var.environment}-app-server-sg"
  description = "enable http/https access on port 80/443 via alb sg"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description     = "https access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  ingress {
    description     = "ec2 instance connect endpoint access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instance_connect_endpoint_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-server-sg"
  }
}

# create security group for the database
resource "aws_security_group" "database_security_group" {
  name        = "${var.project_name}-${var.environment}-database-sg"
  description = "enable mysql/aurora access on port 3306"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "mysql/aurora access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-database-sg"
  }
}

# create security group for the EFS file system
resource "aws_security_group" "efs_security_group" {
  name        = "${var.project_name}-${var.environment}-efs-sg"
  description = "enable nfs access on port 2049"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "nfs access"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app_server_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-efs-sg"
  }
}