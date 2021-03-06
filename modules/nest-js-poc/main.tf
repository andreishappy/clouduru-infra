# ----------
# Networking
# ----------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ---------------
# Security Groups
# ---------------

resource "aws_security_group" "load_balancer" {
  name        = "load-balancer-sg"
  description = "controls access to the Application Load Balancer (ALB)"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "allow inbound access from the ALB only"

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------
# Load Balancer
# -------------

resource "aws_lb" "nest_js_poc" {
  name               = "alb"
  subnets            = data.aws_subnet_ids.default.ids
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
}

resource "aws_lb_listener" "nest_js_poc" {
  load_balancer_arn = aws_lb.nest_js_poc.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nest_js_poc.arn
  }
}

resource "aws_lb_target_group" "nest_js_poc" {
  name        = "nest-js-poc"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "90"
    protocol            = "HTTP"
    matcher             = "200-299"
    timeout             = "20"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

# ---
# ECR
# ---

resource "aws_ecr_repository" "repo" {
  name = "nest-js-poc"
}

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.repo.name
  # Keep latest 2 images
  policy = file("${path.module}/ecr-lifecycle-policy.json")
}

# TODO: at the moment this policy allows andrei to access, but no one else
resource "aws_ecr_repository_policy" "access-policy" {
  repository = aws_ecr_repository.repo.name
  policy = file("${path.module}/ecr-access-policy.json")
}
# ---
# IAM
# ---

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# -------
# Fargate
# -------

//data "template_file" "nest-js-app" {
//  template = file("${path.module}/task-definition.json")
//  vars = {
//    aws_ecr_repository = aws_ecr_repository.repo.repository_url
//    tag                = "latest"
//    app_port           = 80
//  }
//}
//
//resource "aws_ecs_task_definition" "service" {
//  family                   = "nest-js-poc"
//  network_mode             = "awsvpc"
//  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
//  cpu                      = 256
//  memory                   = 2048
//  requires_compatibilities = ["FARGATE"]
//  container_definitions    = data.template_file.nest-js-app.rendered
//}
//
//resource "aws_ecs_cluster" "nest_js_poc" {
//  name = "nest-js-pos-cluster"
//}
//
//resource "aws_ecs_service" "nest_js_poc" {
//  name            = "nest-js-poc"
//  cluster         = aws_ecs_cluster.nest_js_poc.id
//  task_definition = aws_ecs_task_definition.service.arn
//  desired_count   = 1
//  launch_type     = "FARGATE"
//
//  network_configuration {
//    security_groups  = [aws_security_group.ecs_tasks.id]
//    subnets          = data.aws_subnet_ids.default.ids
//    assign_public_ip = true
//  }
//
//  load_balancer {
//    target_group_arn = aws_lb_target_group.nest_js_poc.arn
//    container_name   = "nest-js-poc"
//    container_port   = 3000
//  }
//
//  depends_on = [aws_lb_listener.nest_js_poc, aws_iam_role_policy_attachment.ecs_task_execution_role]
//}

# ----------
# Cloudwatch
# ----------

resource "aws_cloudwatch_log_group" "nest_js_poc" {
  name = "awslogs-nest-js-poc"
}


# -------
# Outputs
# -------

output "ecr_repository_url" {
  value = aws_ecr_repository.repo.repository_url
}

output "public_url" {
  value = aws_lb.nest_js_poc.dns_name
}