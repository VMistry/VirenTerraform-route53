provider "aws" {
  region  = "eu-west-1"
}

# create a vpc
resource "aws_vpc" "app" {
  cidr_block = "${var.cidr_block}"

  tags {
    Name = "${var.name}"
  }
}

# internet gateway
resource "aws_internet_gateway" "app" {
  vpc_id = "${aws_vpc.app.id}"

  tags {
    Name = "${var.name}"
  }
}

module "app" {
  source = "./modules/app_tier"
  vpc_id = "${aws_vpc.app.id}"
  name = "virenApp"
  user_data = "${data.template_file.app_init.rendered}"
  ig_id = "${aws_internet_gateway.app.id}"
  ami_id = "${var.app_ami_id}"
}

module "db" {
  source = "./modules/db_tier"
  vpc_id = "${aws_vpc.app.id}"
  name = "virendb"
  app_sgid = "${module.app.security_group_id}"
  app_scb = "${module.app.subnet_cidr_block}"
  ami_id = "${var.db_ami_id}"
}

//////

resource "aws_launch_configuration" "virenconf" {
  name_prefix   = "virenLC"
  image_id      = "${var.app_ami_id}"
  instance_type = "t2.micro"
  security_groups = ["${module.app.security_group_id}"]
  user_data = "${data.template_file.app_init.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.virenLB.arn}"
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.virenTG.arn}"
  }
}

resource "aws_autoscaling_group" "virenASG" {
  name                 = "virenASG"
  launch_configuration = "${aws_launch_configuration.virenconf.name}"
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  target_group_arns = ["${aws_lb_target_group.virenTG.arn}"]
  vpc_zone_identifier       = ["${module.app.subnet_app_id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "virenTG" {
  name     = "virentg"
  port     = 80
  protocol = "TCP"
  vpc_id   = "${aws_vpc.app.id}"
}

resource "aws_lb" "virenLB" {
  name               = "virenlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["${module.app.subnet_app_id}"]

  tags {
    Environment = "production"
  }
}

# load the init template
data "template_file" "app_init" {
   template = "${file("./scripts/app/init.sh.tpl")}"
   vars {
      db_host="mongodb://${module.db.instance_id}:27017/posts"
   }
}

resource "aws_route53_record" "www" {
  zone_id = "${var.zone_id}"
  name    = "virenAPP"
  type    = "A"

  alias {
    name                   = "${aws_lb.virenLB.dns_name}"
    zone_id                = "${aws_lb.virenLB.zone_id}"
    evaluate_target_health = true
  }
}

# ### load_balancers
# resource "aws_security_group" "elb"  {
#   name = "${var.name}-elb"
#   description = "Allow all inbound traffic through port 80 and 443."
#   vpc_id = "${aws_vpc.app.id}"
#
#   ingress {
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     cidr_blocks     = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     cidr_blocks     = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     cidr_blocks     = ["0.0.0.0/0"]
#   }
#   tags {
#     Name = "${var.name}-elb"
#   }
# }
#
# #### ELB ####
#
# resource "aws_elb" "elb" {
#   name = "${var.name}-app-elb"
#   subnets = ["${module.app.subnet_app_id}",]
#   security_groups = ["${aws_security_group.elb.id}"]
#   internal = "${var.internal}"
#
#   listener {
#     instance_port = 80
#     instance_protocol = "http"
#     lb_port = 80
#     lb_protocol = "http"
#   }
#
#   tags {
#     Name = "${var.name}-elb"
#   }
# }
#
# #### AUTOSCALING GROUP ####
#
# resource "aws_launch_configuration" "app" {
#   name_prefix = "${var.name}-app"
#   image_id = "${var.app_ami_id}"
#   instance_type = "t2.micro"
#   user_data = "${data.template_file.app_init.rendered}"
#   security_groups = ["${module.app.security_group_id}"]
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# resource "aws_autoscaling_group" "app" {
#   load_balancers = ["${aws_elb.elb.id}"]
#   name = "${var.name}-${aws_launch_configuration.app.name}-app"
#   # name = "${var.name}-app"
#   min_size = 1
#   max_size = 3
#   min_elb_capacity = 1
#   desired_capacity = 2
#   vpc_zone_identifier = ["${module.app.subnet_app_id}"]
#   launch_configuration = "${aws_launch_configuration.app.id}"
#   tags {
#     key = "Name"
#     value = "${var.name}-app-${count.index + 1 }"
#     propagate_at_launch = true
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }
