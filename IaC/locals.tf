locals {
  tags = {
    created_by = "terraform"
    environment = "DEV"
  }

  module_path        = abspath(path.module)
  worker_path        = abspath("${path.module}/../worker/")
  deploy_path        = abspath("${path.module}/../deploy.zip")
  migration_path     = abspath("${path.module}/../migrations/initdb.sql")
}