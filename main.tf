# provider "aws" {
#   region = "us-east-1"
# }

resource "aws_dynamodb_table" "games_logs" {
  name           = "GamesLogs"
  billing_mode   = "PROVISIONED"
  hash_key       = "logId"
  read_capacity  = 20
  write_capacity = 20
  range_key      = "timestamp"

  attribute {
    name = "logId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}


#Lambda IAM execution role
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Basic lambda execution role policy 
resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda_policy_attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


#policy to allow lambda to scan dynamoDB table
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-scan-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "dynamodb:Scan",
        Resource = "arn:aws:dynamodb:us-east-1:172234530661:table/GamesLogs"
      }
    ]
  })
}

#Attatching lambda-dynamodb policy to lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_dynamo" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}


#Lambda function to save logs
resource "aws_lambda_function" "save_log" {
  filename         = "${path.module}/save_log.zip"
  function_name    = "SaveLogFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "save_log.lambda_handler"
  runtime          = "python3.9"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.games_logs.name
    }
  }
}


#Lambda function to get the logs
resource "aws_lambda_function" "get_logs" {
  filename         = "${path.module}/get_logs.zip"
  function_name    = "GetLogsFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "get_logs.lambda_handler"
  runtime          = "python3.9"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.games_logs.name
    }
  }
}


#Basic rest API gateway 
resource "aws_api_gateway_rest_api" "logs_api" {
  name = "GamesLogsAPI"
}

resource "aws_api_gateway_resource" "logs_resource" {
  rest_api_id = aws_api_gateway_rest_api.logs_api.id
  parent_id   = aws_api_gateway_rest_api.logs_api.root_resource_id
  path_part   = "games_logs"
}

# Post method execution
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.logs_api.id
  resource_id   = aws_api_gateway_resource.logs_resource.id
  http_method   = "POST"
  authorization = "NONE"
}


#Get method execution
resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.logs_api.id
  resource_id   = aws_api_gateway_resource.logs_resource.id
  http_method   = "GET"
  authorization = "NONE"
}


#post_logs lambda integration
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.logs_api.id
  resource_id = aws_api_gateway_resource.logs_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.save_log.invoke_arn
}

#gett_logs lambda integration
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id = aws_api_gateway_rest_api.logs_api.id
  resource_id = aws_api_gateway_resource.logs_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "GET"
  uri = aws_lambda_function.get_logs.invoke_arn
}


#permission for API gateway to invoke post_logs lambda function
resource "aws_lambda_permission" "api_gateway_post" {
  statement_id  = "AllowAPIGatewayInvokePOST"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_log.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.logs_api.execution_arn}/*"
}


#permissions for API gateway to invoke get_logs lambda function
resource "aws_lambda_permission" "api_gateway_get" {
  statement_id  = "AllowAPIGatewayInvokeGET"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_logs.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.logs_api.execution_arn}/*"
}

output "api_endpoint" {
  value = "${aws_api_gateway_rest_api.logs_api.execution_arn}/games_logs"
}
