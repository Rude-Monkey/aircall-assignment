locals {
    lambda_zip_file = "sre-hiring-test/resize.zip"
}

resource "aws_lambda_function" "resize_lambda" {
  filename      = local.lambda_zip_file
  function_name = "resize_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "app.lambdaHandler"
  timeout = 30

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256(local.lambda_zip_file)

  runtime = "nodejs12.x"

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.my_bucket.bucket
    }
  }
}