# ==============================================================================
# Alerting
# ==============================================================================
#
# One topic for every alarm in the account; the budget alarm reuses it.
#
# Unencrypted on purpose: SSE with the AWS-managed `aws/sns` key would block
# CloudWatch from publishing (its key policy can't be extended), and a
# customer-managed key buys nothing for alarm names and states.
resource "aws_sns_topic" "alerts" {
  name = "alerts"
}

# Email subscriptions start as `PendingConfirmation` until the link in AWS's
# confirmation mail is clicked; Terraform can't do that step.
resource "aws_sns_topic_subscription" "alerts_email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Both DNSSEC metrics read 1 when something needs action, 0 otherwise. Missing
# data is not breaching: the metrics only exist while the zone is signing.
#
# Hourly Maximum: a key problem needs action within days (the DS TTL and
# resolver caches buy time), not minutes, and an hour still catches a metric
# that is published less often than every period.
locals {
  dnssec_alarms = {
    internal_failure = {
      metric      = "DNSSECInternalFailure"
      description = "Route 53 DNSSEC is in INTERNAL_FAILURE for ${local.domain_name}: signing may have stopped"
    }
    ksk_needs_action = {
      metric      = "DNSSECKeySigningKeysNeedingAction"
      description = "A KSK for ${local.domain_name} needs action (usually the KMS key is disabled, missing, or its policy broke)"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "dnssec" {
  for_each = local.dnssec_alarms

  alarm_name        = "route53-${each.value.metric}-${local.domain_name}"
  alarm_description = each.value.description

  namespace   = "AWS/Route53"
  metric_name = each.value.metric
  dimensions  = { HostedZoneId = module.dns.zone_id }
  statistic   = "Maximum"
  period      = 3600

  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
