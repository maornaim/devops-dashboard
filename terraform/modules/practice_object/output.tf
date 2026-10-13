output "object_key" {
  description = "Key of the created S3 object"
  value       = aws_s3_object.this.key
}
