variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "object_key" {
  description = "Key of the S3 object"
  type        = string
}

variable "object_content" {
  description = "Content stored in the S3 object"
  type        = string
}
