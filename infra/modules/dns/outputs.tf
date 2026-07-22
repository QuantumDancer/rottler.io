output "zone_id" {
  description = "Hosted zone ID, consumed by the cert and static-site modules"
  value       = aws_route53_zone.website.zone_id
}

output "name_servers" {
  description = "Delegation nameservers — must match the NS record held by the parent zone"
  value       = aws_route53_zone.website.name_servers
}
