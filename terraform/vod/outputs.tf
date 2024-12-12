# Output S3 Bucket Names
output "s3_bucket_name_ap_south_1" {
  value = aws_s3_bucket.vod_bucket_ap_south_1.bucket
}

output "s3_bucket_name_us_west_1" {
  value = aws_s3_bucket.vod_bucket_us_west_1.bucket
}

output "s3_bucket_name_us_east_1" {
  value = aws_s3_bucket.vod_bucket_us_east_1.bucket
}
