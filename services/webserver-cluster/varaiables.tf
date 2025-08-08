variable "claster_name" {
  description = "The name of the web server cluster"
  type        = string
  default     = "webserver-cluster" 
}

variable "db_remote_state_bucket" {
  description = "The S3 bucket name for the remote state of the database"
  type        = string
}

variable "db_remote_state_key" {
  description = "The S3 key for the remote state of the database"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to use for the web server"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the web server cluster"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the web server cluster"
  type        = number
}

variable "server_port" {
  description = "Port number for the HTTP server"
  type        = number
  default     = 8080
}