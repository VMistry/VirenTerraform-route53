output subnet_app_id {
  description = "The id of the subnet"
  value = "${aws_subnet.app.id}"
}

output subnet_cidr_block {
  description = "the cidr block of the subnet"
  value = "${aws_subnet.app.cidr_block}"
}

output security_group_id{
  description = "This looks at the security group of the app"
  value = "${aws_security_group.app.id}"
}
