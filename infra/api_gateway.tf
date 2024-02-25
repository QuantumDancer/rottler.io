resource "aws_apigatewayv2_api" "view_counter" {
  name          = "view-counter-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "view_counter_lambda_integration" {
  api_id                 = aws_apigatewayv2_api.view_counter.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.view_counter.invoke_arn
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "view_counter" {
  api_id    = aws_apigatewayv2_api.view_counter.id
  route_key = "PUT /view-counter"
  target    = "integrations/${aws_apigatewayv2_integration.view_counter_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "view_counter" {
  api_id      = aws_apigatewayv2_api.view_counter.id
  name        = "api"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.view_counter_api.arn
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#apigateway-cloudwatch-log-formats
    format = jsonencode({
      requestId : "$context.requestId",
      extendedRequestId : "$context.extendedRequestId",
      ip : "$context.identity.sourceIp",
      caller : "$context.identity.caller",
      user : "$context.identity.user",
      requestTime : "$context.requestTime",
      httpMethod : "$context.httpMethod",
      resourcePath : "$context.resourcePath",
      status : "$context.status",
      protocol : "$context.protocol",
      responseLength : "$context.responseLength"
    })
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_deployment
resource "aws_apigatewayv2_deployment" "view_counter" {
  api_id      = aws_apigatewayv2_api.view_counter.id
  description = "Deployment for the ViewCounter API"

  triggers = {
    redeployment = sha1(join(",", tolist([
      jsonencode(aws_apigatewayv2_integration.view_counter_lambda_integration),
      jsonencode(aws_apigatewayv2_route.view_counter),
    ])))
  }

  lifecycle {
    create_before_destroy = true
  }
}
