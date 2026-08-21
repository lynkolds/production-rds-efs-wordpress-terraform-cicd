resource "aws_backup_vault" "efs_backup_vault" {
  name = "${var.project_name}-${var.environment}-efs-backup-vault"
}

resource "aws_backup_plan" "efs_backup_plan" {
  name = "${var.project_name}-${var.environment}-efs-backup-plan"

  rule {
    rule_name         = "daily-efs-backup"
    target_vault_name = aws_backup_vault.efs_backup_vault.name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = 30
    }
  }
}

resource "aws_backup_selection" "efs_backup_selection" {
  name         = "${var.project_name}-${var.environment}-efs-backup-selection"
  iam_role_arn = data.aws_iam_role.aws_backup_role.arn
  plan_id      = aws_backup_plan.efs_backup_plan.id

  resources = [
    aws_efs_file_system.efs_file_system.arn
  ]
}
