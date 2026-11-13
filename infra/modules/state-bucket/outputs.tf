output "bucket" {
  description = "State bucket name, for the `bucket` argument of the account's backend blocks"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "State bucket ARN, for IAM policies that grant a CI role access to its state"
  value       = aws_s3_bucket.state.arn
}
