# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "view_counter_api" {
  name              = "ViewCounterAPI"
  retention_in_days = 7
}
