terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "upload_bucket" {
  bucket = "${var.s3_bucket_name}-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "upload_bucket_versioning" {
  bucket = aws_s3_bucket.upload_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "upload_bucket_pab" {
  bucket = aws_s3_bucket.upload_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "upload_bucket_encryption" {
  bucket = aws_s3_bucket.upload_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "genai_lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "genai_lambda_policy"
  role = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"],
        Resource = [aws_s3_bucket.upload_bucket.arn, "${aws_s3_bucket.upload_bucket.arn}/*"]
      },
      {
        Effect = "Allow",
        Action = ["transcribe:StartMedicalTranscriptionJob", "transcribe:GetMedicalTranscriptionJob"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../lambda"
  output_path = "../lambda/lambda.zip"
  excludes    = ["lambda.zip"]
}

resource "aws_cloudwatch_log_group" "process_audio_logs" {
  name              = "/aws/lambda/genai_process_audio"
  retention_in_days = 14
}

resource "aws_lambda_function" "process_audio" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "genai_process_audio"
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 300
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.upload_bucket.bucket
    }
  }
  depends_on = [aws_cloudwatch_log_group.process_audio_logs]
}

resource "aws_cloudwatch_log_group" "presign_url_logs" {
  name              = "/aws/lambda/genai_presign_url"
  retention_in_days = 14
}

resource "aws_lambda_function" "presign_url" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "genai_presign_url"
  handler          = "presign_url.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      UPLOAD_BUCKET = aws_s3_bucket.upload_bucket.bucket
    }
  }
  depends_on = [aws_cloudwatch_log_group.presign_url_logs]
}

resource "aws_apigatewayv2_api" "genai_api" {
  name          = "genai_api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    max_age          = 86400
  }
}

resource "aws_apigatewayv2_integration" "lambda_process_integration" {
  api_id           = aws_apigatewayv2_api.genai_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.process_audio.arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "lambda_presign_integration" {
  api_id           = aws_apigatewayv2_api.genai_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.presign_url.arn
  integration_method = "GET"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "process_route" {
  api_id    = aws_apigatewayv2_api.genai_api.id
  route_key = "POST /invoke"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_process_integration.id}"
}

resource "aws_apigatewayv2_route" "presign_route" {
  api_id    = aws_apigatewayv2_api.genai_api.id
  route_key = "GET /presign"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_presign_integration.id}"
}

resource "aws_lambda_permission" "apigw_lambda_process" {
  statement_id  = "AllowAPIGatewayInvokeProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_audio.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.genai_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_lambda_presign" {
  statement_id  = "AllowAPIGatewayInvokePresign"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign_url.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.genai_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.genai_api.id
  name        = "$default"
  auto_deploy = true
}

