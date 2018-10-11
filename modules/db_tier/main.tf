# DB
# create a subnet



resource "aws_subnet" "db" {
  vpc_id = "${var.vpc_id}"
  cidr_block = "10.2.1.0/24"
  map_public_ip_on_launch = false
  availability_zone = "eu-west-1a"
  tags {
    Name = "${var.name}-db"
  }
}

# security
resource "aws_security_group" "db"  {
  name = "${var.name}-db"
  description = "${var.name} db access"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port       = "27017"
    to_port         = "27017"
    protocol        = "tcp"
    security_groups = ["${var.app_sgid}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.name}-db"
  }
}

resource "aws_network_acl" "db" {
  vpc_id = "${var.vpc_id}"

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "${var.app_scb}"
    from_port  = 27017
    to_port    = 27017
  }

  # EPHEMERAL PORTS

  egress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "${var.app_scb}"
    from_port  = 1024
    to_port    = 65535
  }

  subnet_ids   = ["${aws_subnet.db.id}"]

  tags {
    Name = "${var.name}-db"
  }
}

# public route table
resource "aws_route_table" "db" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "${var.name}-db-private"
  }
}

resource "aws_route_table_association" "db" {
  subnet_id      = "${aws_subnet.db.id}"
  route_table_id = "${aws_route_table.db.id}"
}

# launch an instance
resource "aws_instance" "db" {
  ami           = "${var.ami_id}"
  subnet_id     = "${aws_subnet.db.id}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  instance_type = "t2.micro"
  tags {
      Name = "${var.name}-db"
  }
}
