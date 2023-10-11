variable "username" {
  type        = string
  description = "INWX username"
  nullable    = false
}

variable "password" {
  type        = string
  description = "INWX password"
  nullable    = false
  sensitive   = true
}

variable "tan" {
  type        = string
  description = "INWX mobile TAN"
  nullable    = false
  sensitive   = true

  validation {
    condition     = can(regex("\\d{6}", var.tan))
    error_message = "The TAN must be exactly 6 digits"
  }
}

variable "street_address" {
  type        = string
  description = "Domain contact street address"
  nullable    = false
}

variable "city" {
  type        = string
  description = "Domain contact city"
  nullable    = false
}

variable "postal_code" {
  type        = string
  description = "Domain contact postal code"
  nullable    = false
}

variable "country_code" {
  type        = string
  description = "Domain contact country code"
  nullable    = false

  validation {
    condition     = can(regex("[A-Z]{2}", var.country_code))
    error_message = "The country code must be 2 upper case characters"
  }
}

variable "phone_number" {
  type        = string
  description = "Domain contact phone number: '+<area code>.<number>'"
  nullable    = false

  validation {
    condition     = can(regex("\\+\\d+\\.\\d+", var.phone_number))
    error_message = "The phone number must match '+<area code>.<number>'"
  }
}

variable "email" {
  type        = string
  description = "Domain contact email"
  nullable    = false
}
