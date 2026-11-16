variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "c7i-flex.large"
}

variable "admin_cidrs" {
  type    = list(string)
  default = ["52.202.119.114/32"]
}

variable "node_instance_type" {
  default = "c7i-flex.large"
}
