resource "aws_s3_bucket" "my_bucket" {
  bucket = "aircall-test-resized-images"
  acl    = "public-read"
}