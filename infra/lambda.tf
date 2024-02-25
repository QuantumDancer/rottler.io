data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_dynamodb_access" {
  name        = "lambda_dynamodb_access"
  description = "IAM policy for accessing DynamoDB from Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.view_counter.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_access.arn
}

data "archive_file" "lambda_counter_zip" {
  type        = "zip"
  source_file = "${path.module}/../backend/counter.py"
  output_path = "${path.module}/../backend/counter.zip"
}

resource "aws_lambda_function" "view_counter" {
  function_name = "ViewCounter"
  handler       = "counter.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.12"

  filename         = data.archive_file.lambda_counter_zip.output_path
  source_code_hash = data.archive_file.lambda_counter_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.view_counter.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "view_counter_allow_api_gateway" {
  statement_id  = "AllowInvokationFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.view_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.view_counter.execution_arn}/*/*/view-counter"
}
