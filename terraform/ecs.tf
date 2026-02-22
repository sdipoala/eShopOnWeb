resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  tags = {
    Name = "${var.app_name}-cluster"
  }
}

resource "aws_ecs_task_definition" "web" {
  family                   = "${var.app_name}-web"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-web"
      image = "${aws_ecr_repository.web.repository_url}:${local.src_hash}"

      portMappings = [
        {
          containerPort = 5106
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        }
      ]

      secrets = [
        {
          name      = "ConnectionStrings__CatalogConnection"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:CatalogConnection::"
        },
        {
          name      = "ConnectionStrings__IdentityConnection"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:IdentityConnection::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}-web"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  depends_on = [null_resource.docker_build_web]

  tags = {
    Name = "${var.app_name}-web"
  }
}

resource "aws_ecs_task_definition" "razorpages" {
  family                   = "${var.app_name}-razorpages"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.app_name}-razorpages"
      image = "${aws_ecr_repository.razorpages.repository_url}:${local.src_hash}"

      portMappings = [
        {
          containerPort = 5107
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        }
      ]

      secrets = [
        {
          name      = "ConnectionStrings__CatalogConnection"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:CatalogConnection::"
        },
        {
          name      = "ConnectionStrings__IdentityConnection"
          valueFrom = "${aws_secretsmanager_secret.db_credentials.arn}:IdentityConnection::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.app_name}-razorpages"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  depends_on = [null_resource.docker_build_razorpages]

  tags = {
    Name = "${var.app_name}-razorpages"
  }
}

resource "aws_ecs_service" "web" {
  name            = "${var.app_name}-web"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "${var.app_name}-web"
    container_port   = 5106
  }

  depends_on = [
    aws_lb_listener.web,
    aws_iam_role_policy_attachment.ecs_task_execution_managed,
  ]

  tags = {
    Name = "${var.app_name}-web"
  }
}

resource "aws_ecs_service" "razorpages" {
  name            = "${var.app_name}-razorpages"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.razorpages.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.razorpages.arn
    container_name   = "${var.app_name}-razorpages"
    container_port   = 5107
  }

  depends_on = [
    aws_lb_listener.razorpages,
    aws_iam_role_policy_attachment.ecs_task_execution_managed,
  ]

  tags = {
    Name = "${var.app_name}-razorpages"
  }
}
