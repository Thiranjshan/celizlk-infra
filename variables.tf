variable "resource_group_name" {
  default = "celiz_group"          # your actual resource groupname
}

variable "location" {
  default = "Central India"    # your actual region — must match exactly
}

variable "pg_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}