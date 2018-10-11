variable "vpc_id" {
  description = "the vpc to help launch the app"
}

variable "name" {
  description = "the name given to all apps"
}

variable "user_data"{
  description = "The user data provides the bash code"
}

variable "ig_id"{
  description = "Used to get the AWS internet gate wasy"
}

variable "ami_id"{
  description = "AMI id of the APP"
}
