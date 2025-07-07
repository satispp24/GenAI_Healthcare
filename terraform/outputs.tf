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

output "frontend_url" {
  value = "http://${aws_lb.genai_alb.dns_name}"
  description = "Primary URL to access the GenAI Healthcare POC frontend"
}

output "alb_url" {
  value = "http://${aws_lb.genai_alb.dns_name}"
  description = "Application Load Balancer URL"
}

output "alb_dns_name" {
  value = aws_lb.genai_alb.dns_name
  description = "ALB DNS Name"
}

