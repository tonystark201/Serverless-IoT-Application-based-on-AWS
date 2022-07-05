data "archive_file" "lambda_worker" {
  type = "zip"
  source_dir = local.worker_path
  output_path = local.deploy_path
}

data "aws_availability_zones" "available" {}

data "aws_iot_endpoint" "demo" {
  endpoint_type = "iot:Data-ATS"
}