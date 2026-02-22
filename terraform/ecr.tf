resource "aws_ecr_repository" "web" {
  name                 = "${var.app_name}-web"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-web"
  }
}

resource "aws_ecr_repository" "razorpages" {
  name                 = "${var.app_name}-razorpages"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-razorpages"
  }
}
