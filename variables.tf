
variable "aws_region" {
  description = "AWS region"
  default = "ap-southeast-2"
}

variable "lambda_logstream_name" {
  description = "AWS cloudwatch log stream name"
  default = "test"
}

variable "aws_acc_id" {
  description = "AWS account id"
  default = "<id>"
}
