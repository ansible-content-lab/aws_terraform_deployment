variable "deployment_id" {
  description = "Creates a random string that will be used in tagging for correlating the resources used with a deployment of AAP."
  type    = string
  validation {
    condition     = length(var.deployment_id) == 8 && can(regex("^[a-z]", var.deployment_id))
    error_message = "deployment_id length should be 8 chars and should contain lower case alphabets only"
  }
}
