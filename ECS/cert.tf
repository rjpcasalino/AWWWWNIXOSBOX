# Request a free public SSL certificate via AWS Certificate Manager
resource "aws_acm_certificate" "cert" {
  domain_name       = "rjpc.net"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.rjpc.net" # Covers subdomains like blog.yourdomain.com if needed
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Automatically create the DNS validation records in AWS (if using Route53) 
# OR use the output below to add CNAMEs manually in Fastmail.
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_acm_certificate.cert.domain_validation_options : record.resource_record_name]
}
