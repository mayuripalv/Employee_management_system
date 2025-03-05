# Create Security Group for ASG instances
resource "aws_security_group" "asg_sg" {
  name        = "asg-security-group"
  description = "Security group for ASG instances"
  vpc_id      = var.existing_vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "asg-security-group"
  }
}

# Create Launch Template using existing instance configuration
resource "aws_launch_template" "asg_template" {
  name = "existing-instances-template"
  image_id      = var.instance_ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interfaces {
    device_index                = 0
    associate_public_ip_address = true
    security_groups            = [aws_security_group.asg_sg.id]
    delete_on_termination      = true
  }

  

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "asg-instance"
    }
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name                = "existing-instances-asg"
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = var.existing_subnet_ids
  target_group_arns   = [var.target_group_arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.asg_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}

# Variables remain the same
variable "existing_vpc_id" {
  description = "ID of existing VPC"
  type        = string
}

variable "existing_subnet_ids" {
  description = "List of existing subnet IDs"
  type        = list(string)
}

variable "instance_ami_id" {
  description = "AMI ID from your existing instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type of your existing instances"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair used in your instances"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of target group if using ALB"
  type        = string
}
