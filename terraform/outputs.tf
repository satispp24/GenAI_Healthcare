output "upload_bucket_name" {
  value = aws_s3_bucket.upload_bucket.bucket
}

output "lambda_process_function_name" {
  value = aws_lambda_function.process_audio.function_name
}

output "lambda_presign_function_name" {
  value = aws_lambda_function.presign_url.function_name
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.genai_api.api_endpoint
}

output "api_invoke_url" {
  value = "${aws_apigatewayv2_api.genai_api.api_endpoint}/invoke"
}

output "api_presign_url" {
  value = "${aws_apigatewayv2_api.genai_api.api_endpoint}/presign"
}

