# IAM Role and Policy for EC2 access to S3

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
          "${aws_s3_bucket.vod_bucket_ap_south_1.arn}",
          "${aws_s3_bucket.vod_bucket_ap_south_1.arn}/*",
          "${aws_s3_bucket.vod_bucket_us_west_1.arn}",
          "${aws_s3_bucket.vod_bucket_us_west_1.arn}/*",
          "${aws_s3_bucket.vod_bucket_us_east_1.arn}",
          "${aws_s3_bucket.vod_bucket_us_east_1.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

## IAM for control node to access the ASGs
# Create IAM role
resource "aws_iam_role" "cluster_autoscaler_role" {
  name = "ClusterAutoscalerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "ClusterAutoscalerPolicy"
  description = "Policy for Cluster Autoscaler"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attachment" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = aws_iam_role.cluster_autoscaler_role.name
}

# Create instance profile
resource "aws_iam_instance_profile" "cluster_autoscaler_profile" {
  name = "ClusterAutoscalerProfile"
  role = aws_iam_role.cluster_autoscaler_role.name
}

# resource "aws_instance" "control_node" {
#   # make sure you import the instance to terraform
#   # terraform import aws_instance.control_node <instance id>
#   iam_instance_profile = aws_iam_instance_profile.cluster_autoscaler_profile.name
# }