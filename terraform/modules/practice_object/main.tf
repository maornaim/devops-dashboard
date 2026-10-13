resource "aws_s3_object" "this" {
  bucket  = var.bucket_name
  key     = var.object_key
  content = var.object_content
}
