variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "database_name" {
  type    = string
  default = "gifmachine"
}

variable "database_username" {
  type    = string
  default = "postgres"
}

variable "database_password" {
  type    = string
  default = "CHANGE_ME"
}

variable "instance_class" {
  type    = string
  default = "serverlessv2"
}


variable "repository_name" {
  type    = string
  default = "hudelgado/gifmachine"
}

variable "secret_key_base" {
  type    = string
  default = "NOT_SO_SECRET"
}