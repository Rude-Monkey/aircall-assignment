provider "aws" {
    region="eu-west-1"
}

module "resize_lambda" {
    source = "./modules/resize_lambda"
}

output "api_url" {
  value = module.resize_lambda.api_url
}

output "bucket_url" {
    value = module.resize_lambda.bucket_url
}