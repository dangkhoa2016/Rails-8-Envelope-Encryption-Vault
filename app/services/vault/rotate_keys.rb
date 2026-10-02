module Vault
  class RotateKeys
    Result = Data.define(:scanned, :rotated, :verified)
    ADVISORY_LOCK_ID = 7_410_202_609_27

    def self.call(from:, to:, dry_run: false)
      raise ArgumentError, "FROM and TO must differ" if from == to
      unless KeyProviders::Registry.configured_active_key_id.to_s == to.to_s
        raise ArgumentError, "TO must equal VAULT_ACTIVE_KEK_ID so concurrent/new writes already use the destination KEK"
      end

      provider = KeyProviders::Registry.fetch
      provider.verify_key!(from)
      provider.verify_key!(to)

      AuditEvent.create!(action: "key.rotation_started", metadata: { from: from, to: to, dry_run: dry_run }) unless dry_run
      with_rotation_lock do
        ActiveRecord::Base.transaction(requires_new: true) do
          perform_rotation(from:, to:, dry_run:, provider:)
        end
      end
    rescue StandardError => e
      unless dry_run
        AuditEvent.create!(action: "key.rotation_failed", metadata: { from: from, to: to, error_class: e.class.name }) rescue nil
      end
      raise
    end

    def self.perform_rotation(from:, to:, dry_run:, provider:)
      scanned = rotated = verified = 0

      counts = rotate_relation(VaultItemVersion.where(key_provider: provider.provider_name, kek_id: from), provider, dry_run) do |record|
        item = record.vault_item
        { user_id: item.user_id, vault_item_id: item.id, vault_item_version_id: record.id }
      end
      scanned += counts[0]; rotated += counts[1]; verified += counts[2]

      counts = rotate_relation(MfaSetting.where(key_provider: provider.provider_name, kek_id: from), provider, dry_run) do |record|
        record.encryption_context
      end
      scanned += counts[0]; rotated += counts[1]; verified += counts[2]

      unless dry_run
        KeyRegistry.find_or_initialize_by(provider: provider.provider_name, kek_id: to).tap do |row|
          row.status = "active"
          row.activated_at ||= Time.current
          row.save!
        end
        if (old = KeyRegistry.find_by(provider: provider.provider_name, kek_id: from))
          old.update!(status: "decrypt_only")
        end
        AuditEvent.create!(action: "key.rotation_completed", metadata: { from: from, to: to, rotated: rotated, verified: verified })
      end

      Result.new(scanned:, rotated:, verified:)
    end
    private_class_method :perform_rotation

    def self.rotate_relation(relation, provider, dry_run)
      scanned = rotated = verified = 0
      relation.find_each do |record|
        scanned += 1
        context = yield(record)
        old_dek = provider.unwrap_key(wrapped_key: record.wrapped_dek, key_id: record.kek_id, context: context)
        new_wrapped = provider.wrap_key(dek: old_dek, context: context)
        new_dek = provider.unwrap_key(wrapped_key: new_wrapped, key_id: provider.active_key_id, context: context)
        raise Crypto::KeyWrapError, "rewrap verification failed" unless ActiveSupport::SecurityUtils.secure_compare(old_dek, new_dek)

        verified += 1
        next if dry_run

        record.update_columns(wrapped_dek: new_wrapped, kek_id: provider.active_key_id)
        rotated += 1
      ensure
        old_dek = new_dek = nil
      end
      [ scanned, rotated, verified ]
    end
    private_class_method :rotate_relation

    def self.with_rotation_lock
      connection = ActiveRecord::Base.connection
      acquired = connection.select_value("SELECT pg_try_advisory_lock(#{ADVISORY_LOCK_ID})")
      raise "another key rotation is already running" unless acquired == true || acquired.to_s == "t"
      yield
    ensure
      connection&.execute("SELECT pg_advisory_unlock(#{ADVISORY_LOCK_ID})") if acquired
    end
    private_class_method :with_rotation_lock
  end
end
