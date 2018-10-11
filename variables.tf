variable "name" {
  default="app-viren"
}

variable "db_ami_id" {
  default="ami-0c315fdbc73711cd4"
}

variable "app_ami_id" {
  default="ami-0b1cff04174dfa2ab"
}

variable "cidr_block" {
  default="10.2.0.0/16"
}

variable "internal" {
  description = "should the ELB be internal or external"
  default = "false"
}

variable "zone_id"{
  default="Z3CCIZELFLJ3SC"
}
