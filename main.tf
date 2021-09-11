terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_iam_role" "iam_for_test_lambda" {
  name = "iam_for_test_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "assets/app-package.zip"
  function_name = "test"
  role          = aws_iam_role.iam_for_test_lambda.arn
  handler       = "handler.lambda_handler"

  source_code_hash = filebase64sha256("assets/app-package.zip")

  runtime = "python3.9"

}

resource "aws_lambda_permission" "test_apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # source_arn = "arn:aws:execute-api:${var.myregion}:${var.accountId}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
  source_arn = "arn:aws:execute-api:${var.aws_region}::${aws_api_gateway_rest_api.test_api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.default.path}"
}


resource "aws_api_gateway_rest_api" "test_api" {
  name = "testapi"
}

resource "aws_api_gateway_resource" "default" {
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.test_api.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.default.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.test_api.id
  resource_id             = aws_api_gateway_resource.default.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}