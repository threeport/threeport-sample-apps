variable "region" {
    description = "The AWS region."
    type = string
}

variable "principal" {
    description = "The AWS principal that can assume the distilbert role for managing SageMaker.  See: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_principal.html#Principal_specifying"
    type = string
}

