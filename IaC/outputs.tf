output "iot_endpoint" {
  description = "Iot endpoint"
  value = data.aws_iot_endpoint.demo.endpoint_address
}