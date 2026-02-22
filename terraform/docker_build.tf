# Hash all source files (excluding build artifacts) so Terraform rebuilds
# images only when code actually changes.
locals {
  src_hash     = substr(sha256(join("", [
    for f in sort(fileset("${path.module}/..", "src/**"))
    : filesha256("${path.module}/../${f}")
    if !can(regex("/(obj|bin)/", f))
  ])), 0, 12)
  # Registry hostname only — docker login rejects the full repo URL
  ecr_registry = split("/", aws_ecr_repository.web.repository_url)[0]
}

resource "null_resource" "docker_build_web" {
  triggers = {
    src_hash = local.src_hash
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-Command"]
    working_dir = "${path.module}/.."
    command     = <<-EOT
      docker login --username AWS --password "$(aws ecr get-login-password --region ${var.region})" ${local.ecr_registry}
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker build -f src/Web/Dockerfile -t ${aws_ecr_repository.web.repository_url}:${local.src_hash} -t ${aws_ecr_repository.web.repository_url}:latest .
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker push ${aws_ecr_repository.web.repository_url}:${local.src_hash}
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker push ${aws_ecr_repository.web.repository_url}:latest
      if ($LASTEXITCODE -ne 0) { exit 1 }
    EOT
  }

  depends_on = [aws_ecr_repository.web]
}

resource "null_resource" "docker_build_razorpages" {
  triggers = {
    src_hash = local.src_hash
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-Command"]
    working_dir = "${path.module}/.."
    command     = <<-EOT
      docker login --username AWS --password "$(aws ecr get-login-password --region ${var.region})" ${local.ecr_registry}
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker build -f src/WebRazorPages/Dockerfile -t ${aws_ecr_repository.razorpages.repository_url}:${local.src_hash} -t ${aws_ecr_repository.razorpages.repository_url}:latest .
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker push ${aws_ecr_repository.razorpages.repository_url}:${local.src_hash}
      if ($LASTEXITCODE -ne 0) { exit 1 }
      docker push ${aws_ecr_repository.razorpages.repository_url}:latest
      if ($LASTEXITCODE -ne 0) { exit 1 }
    EOT
  }

  depends_on = [aws_ecr_repository.razorpages]
}
