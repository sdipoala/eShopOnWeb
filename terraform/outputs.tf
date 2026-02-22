output "ecr_web_repository_url" {
  description = "ECR repository URL for the Web (MVC) app"
  value       = aws_ecr_repository.web.repository_url
}

output "ecr_razorpages_repository_url" {
  description = "ECR repository URL for the WebRazorPages app"
  value       = aws_ecr_repository.razorpages.repository_url
}

output "alb_dns_name" {
  description = "ALB DNS name — port 80 serves Web MVC, port 8080 serves RazorPages"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}
