output "zone_id" {
  description = "ID of the consolidated rottler.io zone"
  value       = module.dns.zone_id
}

output "name_servers" {
  description = "Name servers the registrar's NS switch points at, during the cutover"
  value       = module.dns.name_servers
}

output "alerts_topic_arn" {
  description = "SNS topic every alarm in this account notifies"
  value       = aws_sns_topic.alerts.arn
}
