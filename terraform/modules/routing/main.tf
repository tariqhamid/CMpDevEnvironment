##############################################################
#
# Routing module
#
##############################################################
# Load Balancer configuration
##############################################################
resource "aws_alb_target_group" "component" {
  name     = "CCSDEV-${var.type}-cluster-alb-${var.name}-tg"
  port     = "${var.port}"
  protocol = "${upper(var.protocol)}"
  vpc_id   = "${data.aws_vpc.CCSDEV-Services.id}"

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "${upper(var.protocol)}"
    timeout             = "5"
  }

  tags {
    "Name" = "CCSDEV_${var.type}_cluster_alb_${var.name}-tg"
  }
}

resource "aws_alb_listener_rule" "subdomain_rule" {
  listener_arn = "${data.aws_alb_listener.listener.arn}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.component.arn}"
  }

  condition {
    field  = "host-header"
    values = ["${var.name}.${var.domain}"]
  }
}

##############################################################
# DNS configuration
##############################################################
resource "aws_route53_record" "component" {
  zone_id = "${data.aws_route53_zone.base_domain.zone_id}"
  name    = "${var.name}.${var.domain}"
  type    = "A"

  alias {
    name                   = "${data.aws_alb.CCSDEV_cluster_alb.dns_name}"
    zone_id                = "${data.aws_alb.CCSDEV_cluster_alb.zone_id}"
    evaluate_target_health = true
  }
}
