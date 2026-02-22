resource "aws_cloudwatch_log_group" "web" {
  name              = "/ecs/${var.app_name}-web"
  retention_in_days = 30

  tags = {
    Name = "${var.app_name}-web-logs"
  }
}

resource "aws_cloudwatch_log_group" "razorpages" {
  name              = "/ecs/${var.app_name}-razorpages"
  retention_in_days = 30

  tags = {
    Name = "${var.app_name}-razorpages-logs"
  }
}
