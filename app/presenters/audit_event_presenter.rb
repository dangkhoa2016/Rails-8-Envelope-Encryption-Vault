class AuditEventPresenter
  COPY = {
    "user.registered" => [ "Account created", "Your vault account was created." ],
    "user.login_succeeded" => [ "Signed in", "A sign-in to your vault succeeded." ],
    "user.login_failed" => [ "Sign-in failed", "A sign-in attempt was rejected." ],
    "user.logout" => [ "Signed out", "A vault session was signed out." ],
    "user.password_changed" => [ "Password changed", "Your account password was changed and other sessions were revoked." ],
    "user.reauthenticated" => [ "Identity confirmed", "Recent identity verification succeeded for a sensitive action." ],
    "user.reauthentication_failed" => [ "Identity confirmation failed", "A recent identity verification attempt was rejected." ],
    "user.mfa_enabled" => [ "MFA enabled", "Two-factor authentication was enabled." ],
    "user.mfa_disabled" => [ "MFA disabled", "Two-factor authentication was disabled." ],
    "user.mfa_failed" => [ "MFA verification failed", "A two-factor authentication attempt was rejected." ],
    "user.mfa_recovery_codes_regenerated" => [ "Recovery codes regenerated", "Previous unused MFA recovery codes were invalidated and replaced." ],
    "vault_item.created" => [ "Vault item created", "A new encrypted vault item was created." ],
    "vault_item.updated" => [ "Vault item updated", "A new encrypted version of a vault item was created." ],
    "vault_item.revealed" => [ "Secret revealed", "Protected contents were explicitly decrypted for viewing." ],
    "vault_item.exported" => [ "Secret exported", "Protected contents were explicitly exported." ],
    "vault_item.archived" => [ "Vault item archived", "A vault item was moved out of the active vault." ],
    "vault_item.unarchived" => [ "Vault item restored from archive", "An archived vault item was returned to the active vault." ],
    "vault_item.restored" => [ "Historical version restored", "A historical encrypted version was restored as a new version." ],
    "vault_item.favorited" => [ "Added to favorites", "A vault item was pinned for faster access." ],
    "vault_item.unfavorited" => [ "Removed from favorites", "A vault item was unpinned from favorites." ],
    "key.rotation_started" => [ "Key rotation started", "A vault key rotation operation started." ],
    "key.rotation_completed" => [ "Key rotation completed", "A vault key rotation operation completed successfully." ],
    "key.rotation_failed" => [ "Key rotation failed", "A vault key rotation operation did not complete successfully." ]
  }.freeze

  SAFE_CONTEXT_KEYS = {
    "vault_item.created" => %w[kind],
    "vault_item.updated" => %w[version_number],
    "vault_item.restored" => %w[version_number],
    "vault_item.exported" => %w[format],
    "user.login_succeeded" => %w[mfa],
    "user.reauthenticated" => %w[session_rotated],
    "user.password_changed" => %w[other_sessions_revoked session_rotated],
    "user.mfa_enabled" => %w[other_sessions_revoked session_rotated],
    "user.mfa_disabled" => %w[other_sessions_revoked session_rotated],
    "key.rotation_started" => %w[from to dry_run],
    "key.rotation_completed" => %w[from to rotated verified],
    "key.rotation_failed" => %w[from to error_class]
  }.freeze

  AUTH_REQUEST_KEYS = %w[ip_address http_method request_path user_agent].freeze

  CONTEXT_LABELS = {
    "kind" => "Type",
    "version_number" => "Version",
    "format" => "Format",
    "mfa" => "MFA",
    "session_rotated" => "Session rotated",
    "other_sessions_revoked" => "Other sessions revoked",
    "from" => "From key",
    "to" => "To key",
    "dry_run" => "Dry run",
    "rotated" => "Rotated",
    "verified" => "Verified",
    "error_class" => "Error class",
    "ip_address" => "IP address",
    "http_method" => "Request method",
    "request_path" => "Request path",
    "user_agent" => "User-Agent header"
  }.freeze



  CATEGORIES = {
    "Account" => %w[user.registered user.password_changed],
    "Sessions" => %w[user.login_succeeded user.login_failed user.logout user.reauthenticated user.reauthentication_failed],
    "MFA" => %w[user.mfa_enabled user.mfa_disabled user.mfa_failed user.mfa_recovery_codes_regenerated],
    "Vault" => %w[
      vault_item.created vault_item.updated vault_item.revealed vault_item.exported
      vault_item.archived vault_item.unarchived vault_item.restored
      vault_item.favorited vault_item.unfavorited
    ],
    "Keys" => %w[key.rotation_started key.rotation_completed key.rotation_failed]
  }.freeze

  CATEGORY_BY_ACTION = CATEGORIES.each_with_object({}) do |(category, actions), memo|
    actions.each { |action| memo[action] = category }
  end.freeze

  FALLBACK_DESCRIPTION = "A security-relevant vault event was recorded.".freeze

  # Action names encode outcomes; no unverified status is inferred from metadata.
  FAILED_ACTIONS = %w[
    user.login_failed user.reauthentication_failed user.mfa_failed
    key.rotation_failed
  ].freeze
  RECORDED_ACTIONS = %w[key.rotation_started].freeze
  SENSITIVE_ACTIONS = %w[
    user.password_changed user.mfa_enabled user.mfa_disabled
    user.mfa_recovery_codes_regenerated vault_item.revealed
    vault_item.exported vault_item.restored key.rotation_started
    key.rotation_completed key.rotation_failed
  ].freeze

  def self.outcome_for(action)
    candidate = action.to_s
    return "failed" if FAILED_ACTIONS.include?(candidate)
    return "recorded" if RECORDED_ACTIONS.include?(candidate) || !COPY.key?(candidate)

    "completed"
  end

  def self.actions_for_outcome(outcome, actions)
    actions.select { |action| outcome_for(action) == outcome }
  end

  def outcome
    self.class.outcome_for(action)
  end

  def outcome_label
    { "completed" => "Completed", "failed" => "Failed", "recorded" => "Recorded" }.fetch(outcome)
  end

  def sensitive?
    SENSITIVE_ACTIONS.include?(action)
  end




  def self.category_for(action)
    CATEGORY_BY_ACTION.fetch(action.to_s, "Other")
  end

  def self.actions_for_category(category)
    CATEGORIES.fetch(category.to_s, [])
  end

  def category
    self.class.category_for(action)
  end

  def self.for(action)
    new(action:)
  end

  def self.for_event(event)
    new(action: event.action, metadata: event.metadata, request_id: event.request_id, vault_item_id: event.vault_item_id)
  end

  def initialize(action:, metadata: {}, request_id: nil, vault_item_id: nil)
    @action = action.to_s
    @metadata = metadata.to_h.stringify_keys
    @request_id = request_id.to_s.presence
    @vault_item_id = vault_item_id.to_s.presence
  end

  attr_reader :action

  def title
    COPY.fetch(action, [ humanized_action, FALLBACK_DESCRIPTION ]).first
  end

  def description
    COPY.fetch(action, [ humanized_action, FALLBACK_DESCRIPTION ]).last
  end

  def safe_context
    allowed = SAFE_CONTEXT_KEYS.fetch(action, [])
    allowed += AUTH_REQUEST_KEYS if AuditEvent::AUTHENTICATION_ACTIONS.include?(action)
    fields = allowed.filter_map do |key|
      next unless metadata.key?(key)

      [ CONTEXT_LABELS.fetch(key, key.humanize), display_value(metadata[key], key:) ]
    end
    if AuditEvent::AUTHENTICATION_ACTIONS.include?(action) && metadata["user_agent"].present?
      device = SessionDevicePresenter.for(metadata["user_agent"])
      fields.insert(0, [ "Browser", device.browser ], [ "Operating system", device.operating_system ])
    end
    fields
  end

  def correlation_id
    request_id&.first(12)
  end

  def item_reference
    vault_item_id&.first(12)
  end

  private

  attr_reader :metadata, :request_id, :vault_item_id

  def display_value(value, key: nil)
    case value
    when true then "Yes"
    when false then "No"
    else value.to_s.first(key == "user_agent" ? 255 : 80)
    end
  end

  def humanized_action
    action.tr("._-", " ").split.map(&:capitalize).join(" ")
  end
end
