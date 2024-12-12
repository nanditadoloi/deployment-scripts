# Create S3 Buckets in Different Regions

# S3 Bucket in ap-south-1
resource "aws_s3_bucket" "vod_bucket_ap_south_1" {
  provider = aws.ap_south_1
  bucket   = "my-unique-vod-bucket-ap-south-1"
  tags = {
    Name = "VOD S3 Bucket ap-south-1"
  }
}

# S3 Bucket in us-west-1
resource "aws_s3_bucket" "vod_bucket_us_west_1" {
  provider = aws.us_west_1
  bucket   = "my-unique-vod-bucket-us-west-1"
  tags = {
    Name = "VOD S3 Bucket us-west-1"
  }
}

# S3 Bucket in us-east-1
resource "aws_s3_bucket" "vod_bucket_us_east_1" {
  provider = aws.us_east_1
  bucket   = "my-unique-vod-bucket-us-east-1"
  tags = {
    Name = "VOD S3 Bucket us-east-1"
  }
}
