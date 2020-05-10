resource "aws_s3_bucket" "my_bucket" {
  bucket = "aircall-test-resized-images"
  acl    = "public-read"

  #Needed for a dev purpose. You might not want to add this option on a production bucket as it will allow it to be destroyed even when it is not empty.
  force_destroy = true
}