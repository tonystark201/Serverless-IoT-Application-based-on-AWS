resource "random_pet" "lambda_bucket_name" {
  prefix = "demo"
  length = 4
}

###################
# S3 Bucket for Lambda
###################
resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id
  force_destroy = true
}

resource "aws_s3_bucket_acl" "lambda_bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}


resource "aws_s3_object" "lambda_worker" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key    = "deploy.zip"
  source = data.archive_file.lambda_worker.output_path
  etag = filemd5(data.archive_file.lambda_worker.output_path)
}


###################
# SQS For Lambda
###################
resource "aws_sqs_queue" "demo_queue_deadletter" {
  name                      = "demo-deadletter-queue"
  delay_seconds             = 0
  max_message_size          = 102400
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0

  tags = local.tags
}

resource "aws_sqs_queue" "demo_message_queue" {
  name                      = "demo-message-queue"
  delay_seconds             = 0
  max_message_size          = 102400
  message_retention_seconds = 86400
  receive_wait_time_seconds = 0
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.demo_queue_deadletter.arn
    maxReceiveCount     = 4
  })

  tags = local.tags
}

resource "aws_sqs_queue_policy" "demo_message_queue_policy" {
  queue_url = aws_sqs_queue.demo_message_queue.id
  policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Id": "sqspolicy",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": "*",
          "Action": "sqs:*",
          "Resource": "${aws_sqs_queue.demo_message_queue.arn}",
        },
      ]
    }
  )
}

###################
# IAM Role for IOT
###################
resource "aws_iam_role" "demo_iot_role" {
  name = "demo-iot-sqs-role"
  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "iot.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "demo_iot_policy" {
  name         = "demo_iam_policy_iot"
  description  = "IAM policy for iot rule to sqs"
  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sqs:SendMessage*",
        "Resource": "${aws_sqs_queue.demo_message_queue.arn}",
        "Effect": "Allow"
      },
      {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:PutMetricFilter",
                "logs:PutRetentionPolicy",
                "logs:GetLogEvents",
                "logs:DeleteLogStream"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
  }
  )
}

resource "aws_iam_role_policy_attachment" "demo_iot_policy_attach" {
  role        = aws_iam_role.demo_iot_role.name
  policy_arn  = aws_iam_policy.demo_iot_policy.arn
}

###################
# IOT Rule
###################
resource "aws_iot_topic_rule" "demo_iot_rule" {
  name        = "demo_iot_rule"
  description = "demo-iot-rule"
  enabled     = true
  sql         = "SELECT * FROM 'iot/demo/#'"
  sql_version = "2016-03-23"

  sqs {
    queue_url = aws_sqs_queue.demo_message_queue.url
    role_arn  = aws_iam_role.demo_iot_role.arn
    use_base64 = false
  }

  error_action {
    sqs {
      queue_url = aws_sqs_queue.demo_message_queue.url
      role_arn  = aws_iam_role.demo_iot_role.arn
      use_base64 = false
    }
  }
}

###################
# IAM Role for Lambda Function
###################
resource "aws_iam_role" "demo_lambda_role" {
 name   = "demo_iam_role_lambda_function"
 assume_role_policy = jsonencode(
  {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
 )
}

resource "aws_iam_policy" "demo_lambda_policy" {
  name         = "demo_iam_policy_lambda"
  path         = "/"
  description  = "IAM policy for logging from a lambda"
  policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      },
      {
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": "${aws_sqs_queue.demo_message_queue.arn}",
        "Effect": "Allow"
      },
      {
        "Action": [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
  }
  )
}

resource "aws_iam_role_policy_attachment" "demo_lambda_policy_attach" {
  role        = aws_iam_role.demo_lambda_role.name
  policy_arn  = aws_iam_policy.demo_lambda_policy.arn
}

###################
# Create Lambda Function
###################
resource "aws_lambda_function" "demo_lambda_function" {
  function_name     = "demo_lambda_function"

  s3_bucket         = aws_s3_bucket.lambda_bucket.id
  s3_key            = aws_s3_object.lambda_worker.key

  handler           = "worker.main.lambda_handler"
  runtime           = "python3.7"

  source_code_hash  = data.archive_file.lambda_worker.output_base64sha256
  role              = aws_iam_role.demo_lambda_role.arn
  depends_on        = [aws_iam_role_policy_attachment.demo_lambda_policy_attach]
}

resource "aws_lambda_event_source_mapping" "demo_lambda_source" {
  event_source_arn = aws_sqs_queue.demo_message_queue.arn
  function_name    = aws_lambda_function.demo_lambda_function.arn
}


###################
# Create VPC
###################
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = local.tags
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Grant the VPC internet access on its main route table.
resource "aws_route" "route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}



# Create subnets 
resource "aws_subnet" "rds" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "rds-${element(data.aws_availability_zones.available.names, count.index)}"
  }
}

# Create a subnet group with all of the RDS subnets.
resource "aws_db_subnet_group" "rds" {
  name        = "rds-posgres-subnet-group"
  description = "Terraform RDS subnet group"
  subnet_ids  = "${aws_subnet.rds.*.id}"
}

###################
# Create SG for RDS
###################
resource "aws_security_group" "rds" {
  name        = "terraform_rds_security_group"
  description = "Terraform example RDS Postgres server"
  vpc_id      = aws_vpc.vpc.id

  # Keep the instance private by only allowing traffic from the web server.
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-rds-security-group"
  }
}

###################
# Create RDS Instance
###################
resource "aws_db_instance" "demo_postgresql" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "13.3"
  instance_class       = "db.t4g.micro"
  multi_az             = false
  db_name                 = var.postgres_db_name
  username             = var.postgres_db_user
  password             = var.postgres_db_password
  port                 = var.postgres_db_port
  publicly_accessible  = true
  storage_encrypted    = true
  storage_type         = "gp2"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds.id
  vpc_security_group_ids  = [aws_security_group.rds.id]
}


###################
# Initial RDS Database with SQL Script
###################
resource "null_resource" "rds_db_setup" {

  provisioner "local-exec" {

    command = "psql -h ${aws_db_instance.demo_postgresql.address} -p ${aws_db_instance.demo_postgresql.port} -U \"${var.postgres_db_user}\" -d ${var.postgres_db_name} -f \"${local.migration_path}\""

    environment = {
      PGPASSWORD = "${var.postgres_db_password}"
    }
  }
}