resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.app_name}/db-credentials"
  recovery_window_in_days = 0

  tags = {
    Name = "${var.app_name}-db-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    CatalogConnection  = "Host=${aws_db_instance.postgres.address};Port=5432;Database=eshop_catalog;Username=${var.db_username};Password=${random_password.db_password.result};"
    IdentityConnection = "Host=${aws_db_instance.postgres.address};Port=5432;Database=eshop_identity;Username=${var.db_username};Password=${random_password.db_password.result};"
  })
}
