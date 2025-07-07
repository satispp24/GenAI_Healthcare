# S3 Trigger Lambda for SOAP Note Generation

# CloudWatch Log Group for S3 Trigger Lambda
resource "aws_cloudwatch_log_group" "s3_trigger_logs" {
  name              = "/aws/lambda/genai_s3_trigger_soap"
  retention_in_days = 14
}

# S3 Trigger Lambda Function
resource "aws_lambda_function" "s3_trigger_soap" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "genai_s3_trigger_soap"
  handler          = "s3_trigger_soap.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 300
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.upload_bucket.bucket
    }
  }
  
  depends_on = [aws_cloudwatch_log_group.s3_trigger_logs]
}

# S3 Bucket Notification
resource "aws_s3_bucket_notification" "transcript_notification" {
  bucket = aws_s3_bucket.upload_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_soap.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "medical/"
    filter_suffix       = ".json"
  }

  depends_on = [aws_lambda_permission.s3_invoke_lambda]
}

# Lambda Permission for S3
resource "aws_lambda_permission" "s3_invoke_lambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_soap.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.upload_bucket.arn
}

# Upload Only Lambda Function
resource "aws_cloudwatch_log_group" "upload_only_logs" {
  name              = "/aws/lambda/genai_upload_only"
  retention_in_days = 14
}

resource "aws_lambda_function" "upload_only" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "genai_upload_only"
  handler          = "upload_only.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 60
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.upload_bucket.bucket
    }
  }
  
  depends_on = [aws_cloudwatch_log_group.upload_only_logs]
}

# API Gateway Integration for Upload Only
resource "aws_apigatewayv2_integration" "lambda_upload_only_integration" {
  api_id           = aws_apigatewayv2_api.genai_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload_only.arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

# API Gateway Route for Upload Only
resource "aws_apigatewayv2_route" "upload_only_route" {
  api_id    = aws_apigatewayv2_api.genai_api.id
  route_key = "POST /upload-only"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_upload_only_integration.id}"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "apigw_lambda_upload_only" {
  statement_id  = "AllowAPIGatewayInvokeUploadOnly"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_only.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.genai_api.execution_arn}/*/*"
}

# Get Results Lambda Function
resource "aws_cloudwatch_log_group" "get_results_logs" {
  name              = "/aws/lambda/genai_get_results"
  retention_in_days = 14
}

resource "aws_lambda_function" "get_results" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "genai_get_results"
  handler          = "get_results.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.upload_bucket.bucket
    }
  }
  
  depends_on = [aws_cloudwatch_log_group.get_results_logs]
}

# API Gateway Integration for Get Results
resource "aws_apigatewayv2_integration" "lambda_get_results_integration" {
  api_id           = aws_apigatewayv2_api.genai_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.get_results.arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

# API Gateway Route for Get Results
resource "aws_apigatewayv2_route" "get_results_route" {
  api_id    = aws_apigatewayv2_api.genai_api.id
  route_key = "GET /get-results"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_get_results_integration.id}"
}

# Lambda Permission for Get Results
resource "aws_lambda_permission" "apigw_lambda_get_results" {
  statement_id  = "AllowAPIGatewayInvokeGetResults"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_results.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.genai_api.execution_arn}/*/*"
}