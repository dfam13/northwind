module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name    = var.name
  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  security_group_ingress_rules = {
    http = {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      port     = 80
      protocol = "HTTP"
      target_type = "instance"
      create_attachment = false   

      health_check = {
        path    = "/"
        matcher = "200"
      }
    }
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y nginx
systemctl enable nginx
systemctl start nginx
echo "Northwind App Running" > /usr/share/nginx/html/index.html
EOF
  )
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

resource "aws_autoscaling_group" "app" {
  min_size         = 1
  max_size         = 3
  desired_capacity = 1

  vpc_zone_identifier = var.private_subnets

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [
    module.alb.target_groups["app"].arn
  ]
}
