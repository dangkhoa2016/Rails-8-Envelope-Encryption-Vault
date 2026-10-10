if Rails.env.production? && ENV["SKIP_PRODUCTION_BOOT_CHECKS"] != "true"
  errors = []

  %w[DATABASE_URL VAULT_ACTIVE_KEK_ID].each do |name|
    errors << "#{name} is required" if ENV[name].to_s.strip.empty?
  end

  hosts = ENV["APP_HOSTS"].presence || ENV["APP_HOST"].presence
  errors << "APP_HOSTS or APP_HOST is required" if hosts.blank?
  host_values = []
  if hosts.present?
    host_values = hosts.split(",").map(&:strip).reject(&:empty?)
    errors << "APP_HOSTS/APP_HOST must contain at least one host" if host_values.empty?
    errors << "APP_HOSTS/APP_HOST contains an unsafe placeholder" if host_values.any? { |h| h.match?(/[<>]/) || h.match?(/example\.(com|test)\z/i) }
  end

  demo_mode = ENV.fetch("DEMO_MODE", "false") == "true"
  if !demo_mode && host_values.any? { |h| %w[localhost 127.0.0.1 ::1].include?(h.downcase) }
    errors << "localhost/loopback APP_HOSTS are only allowed with DEMO_MODE=true in production"
  end
  if ENV.fetch("ALLOW_SIGNUPS", "false") == "true" && !demo_mode
    errors << "ALLOW_SIGNUPS=true is only allowed with DEMO_MODE=true in production"
  end
  if ENV.fetch("FORCE_SSL", "true") != "true" && !demo_mode
    errors << "FORCE_SSL=false is only allowed with DEMO_MODE=true in production"
  end
  if ENV.fetch("REQUIRE_MFA", "true") != "true" && !demo_mode
    errors << "REQUIRE_MFA=false is only allowed with DEMO_MODE=true in production"
  end
  if ENV.fetch("REAUTH_ON_REVEAL", "true") != "true" && !demo_mode
    errors << "REAUTH_ON_REVEAL=false is only allowed with DEMO_MODE=true in production"
  end

  provider = ENV.fetch("VAULT_KEY_PROVIDER", "local_file")
  case provider
  when "local_file"
    errors << "VAULT_KEK_DIR is required" if ENV["VAULT_KEK_DIR"].to_s.strip.empty?
  when "aws_kms"
    aws_region = ENV["AWS_REGION"].presence || ENV["AWS_DEFAULT_REGION"].presence
    errors << "AWS_REGION or AWS_DEFAULT_REGION is required for aws_kms" if aws_region.blank?
  else
    errors << "VAULT_KEY_PROVIDER=#{provider.inspect} is not supported by this release"
  end

  secret = Rails.application.secret_key_base.to_s
  errors << "SECRET_KEY_BASE/RAILS_MASTER_KEY is missing or too short" if secret.bytesize < 64
  errors << "SECRET_KEY_BASE contains an unsafe placeholder" if secret.match?(/change-me|example|replace-me/i)

  if provider == "local_file" && (dir = ENV["VAULT_KEK_DIR"].presence) && (kid = ENV["VAULT_ACTIVE_KEK_ID"].presence)
    expanded_dir = File.expand_path(dir)
    errors << "VAULT_ACTIVE_KEK_ID has an invalid format" unless kid.match?(/\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}\z/)
    errors << "VAULT_KEK_DIR must be mounted outside the Rails application directory" if expanded_dir == Rails.root.to_s || expanded_dir.start_with?(Rails.root.to_s + File::SEPARATOR)

    begin
      if File.directory?(expanded_dir)
        dir_mode = File.stat(expanded_dir).mode & 0o777
        if (dir_mode & 0o077) != 0
          message = "VAULT_KEK_DIR permissions are too broad (#{format('%o', dir_mode)}); use 0700/0500"
          demo_mode ? Rails.logger.warn("[security-demo] #{message}") : errors << message
        end
      end

      path = File.join(expanded_dir, "#{kid}.key")
      if !File.file?(path)
        errors << "active Vault KEK does not exist: #{path}"
      else
        key_bytes = File.binread(path)
        errors << "active Vault KEK must be exactly 32 bytes" unless key_bytes.bytesize == 32
        mode = File.stat(path).mode & 0o777
        if (mode & 0o077) != 0
          message = "active Vault KEK permissions are too broad (#{format('%o', mode)}); use 0600/0400"
          demo_mode ? Rails.logger.warn("[security-demo] #{message}") : errors << message
        end
      end
    rescue Errno::EACCES => e
      errors << "Vault KEK path is not readable by the runtime user: #{e.message}"
    ensure
      key_bytes = nil
    end
  end

  raise "Production security checks failed:\n- #{errors.join("\n- ")}" if errors.any?
end

Rails.application.config.after_initialize do
  next unless Rails.env.production?
  next if ENV["SKIP_PRODUCTION_BOOT_CHECKS"] == "true"
  next unless ENV.fetch("VAULT_KEY_PROVIDER", "local_file") == "aws_kms"

  KeyProviders::AwsKmsActiveKeyGuard.verify!(ENV.fetch("VAULT_ACTIVE_KEK_ID", ""))
rescue Crypto::KeyProviderConfigurationError, Crypto::KeyProviderUnavailableError => e
  raise "Production AWS KMS registry checks failed: #{e.message}"
end
