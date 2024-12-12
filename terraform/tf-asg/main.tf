provider "aws" {
  region = "ap-south-1"
}

# Create S3 Bucket (without ACLs)
resource "aws_s3_bucket" "vod_bucket" {
  bucket = "my-unique-vod-bucket-name-123"  # Change this to a globally unique name

  tags = {
    Name = "VOD S3 Bucket"
  }
}

# Define S3 Bucket Policy in a separate resource
resource "aws_s3_bucket_policy" "vod_bucket_policy" {
  bucket = aws_s3_bucket.vod_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Deny",
        Principal = "*",
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.vod_bucket.arn}/*"
        ],
        Condition = {
          Bool: {
            "aws:SecureTransport": "false"
          }
        }
      }
    ]
  })
}

# IAM Role for EC2 to Access S3
resource "aws_iam_role" "ec2_role" {
  name               = "ec2-vod-s3-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy to Allow Access to S3
resource "aws_iam_policy" "s3_access_policy" {
  name   = "S3AccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.vod_bucket.arn}",
          "${aws_s3_bucket.vod_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Create IAM Instance Profile for EC2 Instances
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Launch Template for Auto Scaling Group (With IAM Profile for S3 Access)
resource "aws_launch_template" "worker_template" {
  name_prefix = "worker-template"
  
  instance_type = "t2.micro"
  image_id      = "ami-0c5cdba2323106e82"
  
  key_name = "nandita_aws"

  network_interfaces {
    associate_public_ip_address = true
    subnet_id                   = "subnet-045e1cb02633b9a03"
    security_groups             = ["sg-04d62c0f787cd9904"]
  }

  # Attach IAM Instance Profile (to allow S3 access)
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  # User data to automate the kubeadm join command
  user_data = filebase64("userdata.sh")

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "k8s-worker"
    }
  }
}

resource "aws_autoscaling_group" "worker_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = ["subnet-045e1cb02633b9a03"]
  
  launch_template {
    id      = aws_launch_template.worker_template.id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/your-cluster-name"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/your-cluster-name"
    value               = "owned"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Output S3 Bucket Name
output "s3_bucket_name" {
  value = aws_s3_bucket.vod_bucket.bucket
}
