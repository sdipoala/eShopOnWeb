resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP for Web MVC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for RazorPages"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "To ECS Web MVC"
    from_port       = 5106
    to_port         = 5106
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    description     = "To ECS RazorPages"
    from_port       = 5107
    to_port         = 5107
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound (ECR, Secrets Manager via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-sg"
  }
}

resource "aws_security_group_rule" "ecs_from_alb_web" {
  type                     = "ingress"
  from_port                = 5106
  to_port                  = 5106
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.alb.id
  description              = "From ALB to Web MVC"
}

resource "aws_security_group_rule" "ecs_from_alb_razorpages" {
  type                     = "ingress"
  from_port                = 5107
  to_port                  = 5107
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.alb.id
  description              = "From ALB to RazorPages"
}

resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}
