output "certificate_arn" {
  description = "ARN for the CloudFront distribution's viewer certificate"
  value       = aws_acm_certificate.website_cert.arn
}
