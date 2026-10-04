module Demo
  class FixtureBuilder
    DEMO_EMAIL = "showcase@example.test"
    DEMO_ITEMS = [
      [ "login", {
        "schema" => "vault.login.v1",
        "title" => "Acme Analytics",
        "username" => "demo.user@example.test",
        "password" => "demo-only-analytics-password",
        "url" => "https://analytics.example.test",
        "tags" => %w[demo analytics work],
        "notes" => "Sanitized portfolio fixture. No real credential."
      } ],
      [ "api_key", {
        "schema" => "vault.api_key.v1",
        "title" => "Example Payments API",
        "username" => "client_demo_2026",
        "password" => "sk_demo_not_a-real-key-123456",
        "url" => "https://api.example.test",
        "tags" => %w[demo api billing],
        "notes" => "Fake API credential for screenshots and walkthroughs."
      } ],
      [ "database", {
        "schema" => "vault.database.v1",
        "title" => "Demo PostgreSQL",
        "host" => "db.internal.example.test",
        "port" => "5432",
        "database_name" => "showcase",
        "username" => "showcase_app",
        "password" => "demo-db-password-only",
        "tags" => %w[demo database staging],
        "notes" => "Non-routable/example data only."
      } ],
      [ "secure_note", {
        "schema" => "vault.secure_note.v1",
        "title" => "Recovery Checklist",
        "body" => "1. Verify off-site backup\n2. Verify KEK copy\n3. Run restore rehearsal",
        "tags" => %w[demo recovery operations],
        "notes" => "Example operational note."
      } ],
      [ "ssh", {
        "schema" => "vault.ssh.v1",
        "title" => "Demo Application Server",
        "host" => "app-01.example.test",
        "port" => "22",
        "username" => "deploy",
        "password" => "demo-ssh-passphrase-only",
        "tags" => %w[demo server staging],
        "notes" => "Example host only; no real infrastructure."
      } ],
      [ "environment", {
        "schema" => "vault.environment.v1",
        "title" => "Demo Staging Environment",
        "environment" => "staging",
        "entries" => {
          "APP_HOST" => "staging.example.test",
          "API_TOKEN" => "demo-token-only",
          "FEATURE_PREVIEW" => "true"
        },
        "tags" => %w[demo environment staging],
        "notes" => "All values are synthetic."
      } ]
    ].freeze

    Result = Data.define(:user, :items, :created)

    def self.call(password:, email: DEMO_EMAIL, reset: false)
      new(password:, email:, reset:).call
    end

    def initialize(password:, email:, reset:)
      @password = password.to_s
      @email = email.to_s.strip.downcase
      @reset = reset
    end

    def call
      raise ArgumentError, "Demo password must be at least 14 characters." if password.length < 14
      raise ArgumentError, "Demo fixture requires DEMO_MODE=true." unless ActiveModel::Type::Boolean.new.cast(ENV.fetch("DEMO_MODE", "false"))

      user = User.find_or_initialize_by(email_address: email)
      created = user.new_record?
      user.password = password
      user.password_confirmation = password
      user.save!

      reset_existing!(user) if reset
      items = ensure_items!(user)

      Result.new(user:, items:, created:)
    end

    private

    attr_reader :password, :email, :reset

    def reset_existing!(user)
      user.sessions.delete_all
      user.audit_events.delete_all
      user.vault_items.destroy_all
    end

    def ensure_items!(user)
      existing_titles = user.vault_items.includes(:current_version).filter_map do |item|
        Vault::RevealItem.call(user:, item:, audit: false).fetch("title", nil)
      rescue Crypto::Error, ArgumentError
        nil
      end.to_set

      DEMO_ITEMS.filter_map do |kind, payload|
        next if existing_titles.include?(payload.fetch("title"))

        item = Vault::CreateItem.call(user:, kind:, payload:)
        item.update!(favorite: true) if %w[login database].include?(kind)

        if payload.fetch("title") == "Acme Analytics"
          revised = payload.merge(
            "password" => "demo-only-analytics-password-v2",
            "notes" => "Sanitized portfolio fixture with encrypted version history."
          )
          Vault::UpdateItem.call(user:, item:, payload: revised)
        end

        item
      end
    end
  end
end
