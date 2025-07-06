variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for uploads and notes"
  type        = string
  default     = "genai-clinical-audio-bucket-${random_id.bucket_suffix.hex}"
  
  validation {
    condition = (
      length(var.s3_bucket_name) >= 3 && 
      length(var.s3_bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.s3_bucket_name)) &&
      !can(regex("\\.\\.|\\.\\-|\\-\\.", var.s3_bucket_name))
    )
    error_message = "S3 bucket name must be 3-63 chars, lowercase alphanumeric with dots/hyphens, no consecutive special chars."
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

