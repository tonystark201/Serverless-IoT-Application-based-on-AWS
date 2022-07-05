
variable "aws_region" {
  type        = string
  default    = "us-east-1"
  description = "aws_region"
}

variable "aws_access_key" {
  type        = string
  description = "aws_access_key"
}

variable "aws_secret_key" {
  type        = string
  description = "aws_secret_key"
}


variable "postgres_db_name" {
  type        = string
  default    = "postgres"
  description = "Postgres db name"
}

variable "postgres_db_user" {
  type        = string
  default     = "postgres"
  description = "Postgres db user name"
}

variable "postgres_db_password" {
  type        = string
  default     = "postgres"
  description = "Postgres db password"
}

variable "postgres_db_port" {
  type        = number
  default     = 5432
  description = "Postgres db port"
}
