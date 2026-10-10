Rails.application.config.x.vault.key_provider = ENV.fetch("VAULT_KEY_PROVIDER", "local_file")
Rails.application.config.x.vault.active_kek_id = ENV.fetch("VAULT_ACTIVE_KEK_ID", "kek-dev-01")
Rails.application.config.x.vault.kek_dir = ENV.fetch("VAULT_KEK_DIR", Rails.root.join(".local/keks").to_s)
Rails.application.config.x.vault.aws_region = ENV["AWS_REGION"].presence || ENV["AWS_DEFAULT_REGION"]
