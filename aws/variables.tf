variable "region" {
  default = "us-east-1"
}

variable "default_tags" {
  type = map
  default = {
    "project" = "jenkins"
    "creator" = "terraform"
  }
}

variable "my_ip_cidr" {
  type    = list
  default = ["181.58.39.207/32"]
}

variable "amis" {
  type = map
  default = {
    "us-east-1" = "ami-0c94855ba95c71c99"
    "us-west-2" = "ami-fc0b939c"
  }
}
