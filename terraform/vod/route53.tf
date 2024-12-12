# Route 53 Hosted Zone (replace with your actual hosted zone ID)
resource "aws_route53_zone" "nandita_zone" {
  name = "nanditaprojects.click"  # Your domain name
}

# Latency-Based Record for ap-south-1
resource "aws_route53_record" "vod_ap_south_1" {
  zone_id = "Z0725328WQBORMM4PVGJ"
  name    = "vod.nanditaprojects.click"  # Subdomain for your VOD app
  type    = "A"
  alias {
    name                   = aws_lb.app_lb_ap_south_1.dns_name  # ALB DNS for ap-south-1
    zone_id                = aws_lb.app_lb_ap_south_1.zone_id   # ALB hosted zone for ap-south-1
    evaluate_target_health = true
  }
  set_identifier = "ap-south-1"  # Unique identifier for the region
  latency_routing_policy {
    region = "ap-south-1"  # AWS region for this ALB
  }
}

# Latency-Based Record for us-west-1
resource "aws_route53_record" "vod_us_west_1" {
  zone_id = "Z0725328WQBORMM4PVGJ"
  name    = "vod.nanditaprojects.click"
  type    = "A"
  alias {
    name                   = aws_lb.app_lb_us_west_1.dns_name  # ALB DNS for us-west-1
    zone_id                = aws_lb.app_lb_us_west_1.zone_id   # ALB hosted zone for us-west-1
    evaluate_target_health = true
  }
  set_identifier = "us-west-1"
  latency_routing_policy {
    region = "us-west-1"
  }
}

# Latency-Based Record for us-east-1
resource "aws_route53_record" "vod_us_east_1" {
  zone_id = "Z0725328WQBORMM4PVGJ"
  name    = "vod.nanditaprojects.click"
  type    = "A"
  alias {
    name                   = aws_lb.app_lb_us_east_1.dns_name  # ALB DNS for us-east-1
    zone_id                = aws_lb.app_lb_us_east_1.zone_id   # ALB hosted zone for us-east-1
    evaluate_target_health = true
  }
  set_identifier = "us-east-1"
  latency_routing_policy {
    region = "us-east-1"
  }
}
