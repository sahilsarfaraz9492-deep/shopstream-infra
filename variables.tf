variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "admin_cidrs" {
  type    = list(string)
  default = ["52.202.119.114/32"]
}
