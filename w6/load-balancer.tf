resource "aws_elb" "test_lb" {
  name               = "test-lb"

  security_groups    = [aws_security_group.public-sg.id]
  subnets            = [aws_subnet.public_sb.id]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/health"
    interval            = 30
  }
}
