variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name prefix for all resources"
  type        = string
  default     = "eshop"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "eshop_admin"
}

variable "db_name" {
  description = "RDS initial database name (additional databases eshop_catalog / eshop_identity are created by the app at runtime)"
  type        = string
  default     = "eshop"
}
