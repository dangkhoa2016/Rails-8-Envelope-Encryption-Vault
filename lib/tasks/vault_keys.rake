require "openssl"
require "digest"
require "fileutils"
require "io/console"

module VaultTaskHelpers
  module_function

  def read_owner_password
    if ENV["PASSWORD_FILE"].present?
      File.binread(ENV.fetch("PASSWORD_FILE")).sub(/\r?\n\z/, "")
    elsif ENV["PASSWORD"].present?
      warn "WARNING: PASSWORD environment variables may be exposed in shell history/process metadata; prefer PASSWORD_FILE or interactive input."
      ENV.fetch("PASSWORD")
    elsif $stdin.tty?
      $stderr.print "Password: "
      value = $stdin.noecho(&:gets).to_s.chomp
      $stderr.puts
      value
    else
      abort "Provide PASSWORD_FILE, PASSWORD, or run interactively."
    end
  end
end

namespace :vault do
  namespace :keys do
    desc "Generate a 32-byte local-file KEK. ID=kek-2026-01 [DIR=/secure/path]"
    task generate: :environment do
      id = ENV.fetch("ID")
      abort "Invalid key id" unless id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9._-]{0,127}\z/)
      dir = File.expand_path(ENV["DIR"] || Rails.configuration.x.vault.kek_dir)
      FileUtils.mkdir_p(dir, mode: 0o700)
      File.chmod(0o700, dir)
      path = File.join(dir, "#{id}.key")
      flags = File::WRONLY | File::CREAT | File::EXCL
      key = OpenSSL::Random.random_bytes(32)
      File.open(path, flags, 0o600) { |f| f.binmode; f.write(key) }
      File.chmod(0o600, path)
      puts "Created KEK"
      puts "id: #{id}"
      puts "path: #{path}"
      puts "fingerprint: sha256:#{Digest::SHA256.hexdigest(key)}"
      puts "permissions: %o" % (File.stat(path).mode & 0o777)
    rescue Errno::EEXIST
      abort "Refusing to overwrite existing KEK: #{path}"
    ensure
      key = nil
    end

    desc "List local KEK files without printing key material"
    task list: :environment do
      dir = File.expand_path(Rails.configuration.x.vault.kek_dir)
      Dir.glob(File.join(dir, "*.key")).sort.each do |path|
        key = File.binread(path)
        puts [ File.basename(path, ".key"), key.bytesize, "sha256:#{Digest::SHA256.hexdigest(key)}" ].join("\t")
      ensure
        key = nil
      end
    end

    desc "Verify active local KEK can encrypt/decrypt a probe"
    task verify: :environment do
      provider = KeyProviders::Registry.fetch
      context = { user_id: "probe-user", vault_item_id: "probe-item", vault_item_version_id: "probe-version" }
      envelope = Crypto::EnvelopeEncryptor.encrypt(plaintext: "probe", context: context, key_provider: provider)
      recovered = Crypto::EnvelopeEncryptor.decrypt(envelope: envelope, context: context, key_provider: provider)
      abort "verification failed" unless recovered == "probe"
      puts "PASS provider=#{provider.provider_name} kek_id=#{provider.active_key_id}"
    end

    desc "Rewrap DEKs under a new local KEK. FROM=old TO=new [DRY_RUN=1]"
    task rotate: :environment do
      from = ENV.fetch("FROM")
      to = ENV.fetch("TO")
      dry_run = ENV.fetch("DRY_RUN", "0") == "1"
      result = Vault::RotateKeys.call(from: from, to: to, dry_run: dry_run)
      puts "scanned=#{result.scanned} rotated=#{result.rotated} verified=#{result.verified} dry_run=#{dry_run}"
    end
  end

  namespace :owner do
    desc "Create the first owner. EMAIL=you@example.com [PASSWORD_FILE=/secure/file]"
    task create: :environment do
      email = ENV.fetch("EMAIL").strip.downcase
      password = VaultTaskHelpers.read_owner_password
      user = User.find_or_initialize_by(email_address: email)
      if user.persisted?
        puts "Owner already exists: #{email}"
      else
        user.password = password
        user.password_confirmation = password
        user.save!
        puts "Created owner: #{email}"
      end
    ensure
      password = nil
    end

    desc "Emergency self-hosted password reset; revokes every session. EMAIL=... [PASSWORD_FILE=/secure/file]"
    task reset_password: :environment do
      password = VaultTaskHelpers.read_owner_password
      user = User.find_by!(email_address: ENV.fetch("EMAIL").strip.downcase)
      user.update!(password: password, password_confirmation: password)
      user.sessions.update_all(revoked_at: Time.current)
      AuditEvent.create!(user: user, action: "user.password_reset_by_operator", metadata: {})
      puts "Password updated and all sessions revoked for #{user.email_address}"
    ensure
      password = nil
    end
  end
end
