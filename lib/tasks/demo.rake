namespace :demo do
  desc "Create an encrypted synthetic showcase fixture (requires DEMO_MODE=true and DEMO_PASSWORD_FILE)"
  task fixture: :environment do
    password_file = ENV["DEMO_PASSWORD_FILE"].to_s
    abort "DEMO_PASSWORD_FILE must point to a 0600 file containing the demo password." if password_file.empty? || !File.file?(password_file)

    mode = File.stat(password_file).mode & 0o777
    abort "DEMO_PASSWORD_FILE must have mode 0600 (got #{format('%04o', mode)})." unless mode == 0o600

    password = File.binread(password_file).strip
    result = Demo::FixtureBuilder.call(
      password:,
      email: ENV.fetch("DEMO_EMAIL", Demo::FixtureBuilder::DEMO_EMAIL),
      reset: ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_RESET", "false"))
    )

    puts "DEMO_FIXTURE=PASS"
    puts "email=#{result.user.email_address}"
    puts "items_total=#{result.user.vault_items.count}"
    puts "versions_total=#{VaultItemVersion.where(vault_item_id: result.user.vault_items.select(:id)).count}"
    puts "audit_events_total=#{result.user.audit_events.count}"
    puts "created_user=#{result.created}"
  ensure
    password = nil
  end
end
