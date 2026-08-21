#SNS topic for the ASG
resource "aws_sns_topic" "wordpress_alerts" {
  name = "${var.project_name}-${var.environment}-wordpress-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-wordpress-alerts"
  }
}

resource "aws_sns_topic_subscription" "wordpress_email_alerts" {
  topic_arn = aws_sns_topic.wordpress_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

#Launch template for the ASG
resource "aws_launch_template" "wordpress_launch_template" {
  name_prefix   = "${var.project_name}-${var.environment}-wordpress-lt-"
  image_id      = var.wordpress_ami_id
  instance_type = var.instance_type

  user_data = filebase64("${path.module}/../../bash-scripts/launch-template-user-data.sh")

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.wordpress_ec2_instance_profile.arn
  }

  vpc_security_group_ids = [
    aws_security_group.app_server_security_group.id
  ]

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-${var.environment}-wordpress-asg-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-wordpress-launch-template"
  }
}

# ASG
resource "aws_autoscaling_group" "wordpress_asg" {
  name                = "${var.project_name}-${var.environment}-wordpress-asg"
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  vpc_zone_identifier = [
    aws_subnet.private_app_subnet_az1.id,
    aws_subnet.private_app_subnet_az2.id
  ]

  depends_on = [
    aws_efs_mount_target.efs_mount_target_az1,
    aws_efs_mount_target.efs_mount_target_az2
  ]

  target_group_arns = [
    aws_lb_target_group.alb_target_group.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.wordpress_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-wordpress-asg-instance"
    propagate_at_launch = true
  }
}

# ASG Policy
resource "aws_autoscaling_policy" "wordpress_target_tracking_cpu" {
  name                   = "${var.project_name}-${var.environment}-wordpress-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.wordpress_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 60
  }
}

# CloudWatch Alarm for ASG scaling activities
resource "aws_cloudwatch_metric_alarm" "wordpress_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-wordpress-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "WordPress ASG EC2 instances have high CPU usage."

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.wordpress_asg.name
  }

  alarm_actions = [
    aws_sns_topic.wordpress_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.wordpress_alerts.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "wordpress_unhealthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-wordpress-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more WordPress targets are unhealthy behind the ALB."

  dimensions = {
    TargetGroup  = aws_lb_target_group.alb_target_group.arn_suffix
    LoadBalancer = aws_lb.application_load_balancer.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.wordpress_alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.wordpress_alerts.arn
  ]
}

# ASG notifications for scaling events
resource "aws_autoscaling_notification" "wordpress_asg_notifications" {
  group_names = [
    aws_autoscaling_group.wordpress_asg.name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR"
  ]

  topic_arn = aws_sns_topic.wordpress_alerts.arn
}