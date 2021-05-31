variable "environment" {
  description = "Environment name"
  type = string
  default = "DEV"

  validation {
    condition = contains(["DEV", "PROD"], var.environment)
    error_message = "Only “DEV” and “PROD” values allowed."
  }
}

variable "admin" {
  type = object({
    username = string
    public_key = string
  })
  default = {
    username = "admin"
    public_key = ""
  }
  validation {
    condition = length(var.admin.public_key) == 0
    error_message = "No public_key specified, you will not be able to login."
  }
}
