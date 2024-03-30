resource "aws_dynamodb_table" "brattin_notes_table" {
  name = "brattin-notes-table"
  billing_mode = "PROVISIONED"
  read_capacity= "30"
  write_capacity= "30"
  attribute {
    name = "noteId"
    type = "S"
  }
  hash_key = "noteId"
}

resource "aws_iam_role_policy" "dynamodb-lambda-policy" {
  name = "dynamodb_lambda_policy"
  role = aws_iam_role.lambda_exec.id
   policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
           "Effect" : "Allow",
           "Action" : ["dynamodb:*"],
           "Resource" : "${aws_dynamodb_table.brattin_notes_table.arn}"
        }
      ]
   })
}

data "archive_file" "create-note-archive" {
  type = "zip"

  source_file = "lambdas/create-note.js"
  output_path = "lambdas/create-note.zip"
}

resource "aws_lambda_function" "create-note" {
  environment {
    variables = {
      NOTES_TABLE = aws_dynamodb_table.brattin_notes_table.name
    }
  }

  function_name = "create-note"
  handler       = "lambdas/create-note.handler"
  filename      = "lambdas/create-note.zip"

  memory_size = "128"
  timeout     = 10
  runtime     = "nodejs20.x"

  role = aws_iam_role.lambda_exec.arn
}

data "archive_file" "delete-note-archive" {
  type = "zip"

  source_file = "lambdas/delete-note.js"
  output_path = "lambdas/delete-note.zip"
}

resource "aws_lambda_function" "delete-note" {
  environment {
    variables = {
      NOTES_TABLE = aws_dynamodb_table.brattin_notes_table.name
    }
  }

  function_name = "delete-note"
  handler       = "lambdas/delete-note.handler"
  filename      = "lambdas/delete-note.zip"

  memory_size = "128"
  timeout     = 10
  runtime     = "nodejs20.x"

  role = aws_iam_role.lambda_exec.arn
}

data "archive_file" "get-all-notes-archive" {
  type = "zip"

  source_file = "lambdas/get-all-notes.js"
  output_path = "lambdas/get-all-notes.zip"
}

resource "aws_lambda_function" "get-all-notes" {
  environment {
    variables = {
      NOTES_TABLE = aws_dynamodb_table.brattin_notes_table.name
    }
  }

  function_name = "get-all-notes"
  handler       = "lambdas/get-all-notes.handler"
  filename      = "lambdas/get-all-notes.zip"

  memory_size = "128"
  timeout     = 10
  runtime     = "nodejs20.x"

  role = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "brattin_notes" {
  name = "/aws/lambda/${aws_lambda_function.create-note.function_name}"

  retention_in_days = 30
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  # defines IAM role that allows Lambda to access resources in my AWS account
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

# The AWSLambdaBasicExecutionRole allows the Lambda to write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the api gateway needed to expose the lambda functions

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "create_note" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.create-note.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "delete_note" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.delete-note.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "get_all_notes" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.get-all-notes.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "create_note" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /create-note"
  target    = "integrations/${aws_apigatewayv2_integration.create_note.id}"
}

resource "aws_apigatewayv2_route" "delete_note" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /delete-note"
  target    = "integrations/${aws_apigatewayv2_integration.delete_note.id}"
}

resource "aws_apigatewayv2_route" "get_all_notes" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /get-all-notes"
  target    = "integrations/${aws_apigatewayv2_integration.get_all_notes.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw_create_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create-note.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_delete_note" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete-note.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gw_get_all_notes" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-all-notes.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}