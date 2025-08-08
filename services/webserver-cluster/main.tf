locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

resource "aws_launch_template" "this" {
    image_id = "ami-020cba7c55df1f615"
    instance_type = var.instance_type

    user_data = base64encode(templatefile("${path.module}/user-data.sh", {
        db_address = data.terraform_remote_state.db.outputs.address
        db_port    = data.terraform_remote_state.db.outputs.port
        server_port = var.server_port
    })) 
    network_interfaces {
        security_groups = [aws_security_group.servers.id]
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "this" {
    launch_template {
        id      = aws_launch_template.this.id
        version = "$Latest"
    }

    vpc_zone_identifier = data.aws_subnets.default.ids

    target_group_arns = [aws_lb_target_group.this.arn]
    health_check_type = "ELB"

    min_size = var.min_size
    max_size = var.max_size


    tag {
        key = "Name"
        value = var.claster_name
        propagate_at_launch = true
    }

    dynamic "tag" {
        for_each = var.custom_tags
        content {
            key                 = tag.key
            value               = tag.value
            propagate_at_launch = true
        }
    }
}

resource "aws_security_group" "servers" {
    name = "${var.claster_name}-servers"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "this" {
    name = var.claster_name
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.this.arn
    port = local.http_port
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_security_group" "alb" {
    name = "${var.claster_name}-alb"
}

resource "aws_lb_target_group" "this" {
    name = var.claster_name
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher  = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "this" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.this.arn
    }
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type              = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_outbound" {
    type              = "egress"
    security_group_id = aws_security_group.alb.id
    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}