output "certificate_arn" {
  description = "ARN for the CloudFront distribution's viewer certificate, known only once it is issued"
  value       = aws_acm_certificate_validation.website_cert.certificate_arn
}
