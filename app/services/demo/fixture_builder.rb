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
      } ],
      [ "login", {
          "schema" => "vault.login.v1",
          "title" => "Northstar Workspace",
          "username" => "sample.northstar@example.test",
          "password" => "demo-login-secret-only",
          "url" => "https://workspace.example.test",
          "tags" => [
            "demo",
            "login",
            "team"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "login", {
          "schema" => "vault.login.v1",
          "title" => "Helios Issue Tracker",
          "username" => "qa.helios@example.test",
          "password" => "demo-login-secret-only",
          "url" => "https://issues.example.test",
          "tags" => [
            "demo",
            "login",
            "engineering"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "login", {
          "schema" => "vault.login.v1",
          "title" => "Orion Admin Portal",
          "username" => "demo.admin@example.test",
          "password" => "demo-login-secret-only",
          "url" => "https://admin.example.test",
          "tags" => [
            "demo",
            "login",
            "admin"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "api_key", {
          "schema" => "vault.api_key.v1",
          "title" => "Maps Sandbox API",
          "username" => "maps_demo_client",
          "password" => "demo-api-key-not-valid",
          "url" => "https://maps.example.test",
          "tags" => [
            "demo",
            "api",
            "maps"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "api_key", {
          "schema" => "vault.api_key.v1",
          "title" => "Notification Gateway API",
          "username" => "notify_demo_client",
          "password" => "demo-api-key-not-valid",
          "url" => "https://notify.example.test",
          "tags" => [
            "demo",
            "api",
            "messaging"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "api_key", {
          "schema" => "vault.api_key.v1",
          "title" => "Reporting Sandbox API",
          "username" => "reports_demo_client",
          "password" => "demo-api-key-not-valid",
          "url" => "https://reports.example.test",
          "tags" => [
            "demo",
            "api",
            "reports"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "database", {
          "schema" => "vault.database.v1",
          "title" => "Analytics Test Database",
          "host" => "analytics-db.example.test",
          "port" => "5432",
          "database_name" => "analytics_demo",
          "username" => "analytics_user",
          "password" => "demo-db-password-not-real",
          "tags" => [
            "demo",
            "database",
            "analytics"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "database", {
          "schema" => "vault.database.v1",
          "title" => "QA MySQL Replica",
          "host" => "mysql-qa.example.test",
          "port" => "5432",
          "database_name" => "qa_reports",
          "username" => "qa_reader",
          "password" => "demo-db-password-not-real",
          "tags" => [
            "demo",
            "database",
            "qa"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "database", {
          "schema" => "vault.database.v1",
          "title" => "Archive Database Sample",
          "host" => "archive-db.example.test",
          "port" => "5432",
          "database_name" => "archive_demo",
          "username" => "archive_reader",
          "password" => "demo-db-password-not-real",
          "tags" => [
            "demo",
            "database",
            "archive"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "secure_note", {
          "schema" => "vault.secure_note.v1",
          "title" => "Launch Readiness Notes",
          "body" => "Sample launch checklist:\n- Validate sandbox access\n- Confirm placeholder values\n- Review demo screenshots",
          "tags" => [
            "demo",
            "note",
            "launch"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "secure_note", {
          "schema" => "vault.secure_note.v1",
          "title" => "Incident Response Outline",
          "body" => "Example only:\n1. Record the incident\n2. Notify the demo owner\n3. Test a recovery procedure",
          "tags" => [
            "demo",
            "note",
            "incident"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "secure_note", {
          "schema" => "vault.secure_note.v1",
          "title" => "Key Rotation Reminder",
          "body" => "Sandbox checklist:\n- Review example encryption metadata\n- Verify a test rotation\n- Check the audit history",
          "tags" => [
            "demo",
            "note",
            "rotation"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "ssh", {
          "schema" => "vault.ssh.v1",
          "title" => "Demo Worker Node",
          "host" => "worker-01.example.test",
          "port" => "22",
          "username" => "demo_worker",
          "password" => "demo-ssh-password-only",
          "tags" => [
            "demo",
            "ssh",
            "worker"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "ssh", {
          "schema" => "vault.ssh.v1",
          "title" => "Example Build Runner",
          "host" => "runner-qa.example.test",
          "port" => "22",
          "username" => "build_user",
          "password" => "demo-ssh-password-only",
          "tags" => [
            "demo",
            "ssh",
            "ci"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "ssh", {
          "schema" => "vault.ssh.v1",
          "title" => "Example Bastion Host",
          "host" => "bastion.example.test",
          "port" => "22",
          "username" => "demo_operator",
          "password" => "demo-ssh-password-only",
          "tags" => [
            "demo",
            "ssh",
            "bastion"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "environment", {
          "schema" => "vault.environment.v1",
          "title" => "Demo Development Environment",
          "environment" => "development",
          "entries" => {
            "APP_HOST" => "dev.example.test",
            "FEATURE_PREVIEW" => "true",
            "DEMO_ONLY" => "yes"
          },
          "tags" => [
            "demo",
            "environment",
            "development"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "environment", {
          "schema" => "vault.environment.v1",
          "title" => "Demo QA Environment",
          "environment" => "qa",
          "entries" => {
            "APP_HOST" => "qa.example.test",
            "FEATURE_PREVIEW" => "true",
            "DEMO_ONLY" => "yes"
          },
          "tags" => [
            "demo",
            "environment",
            "qa"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "environment", {
          "schema" => "vault.environment.v1",
          "title" => "Demo Preview Environment",
          "environment" => "preview",
          "entries" => {
            "APP_HOST" => "preview.example.test",
            "FEATURE_PREVIEW" => "true",
            "DEMO_ONLY" => "yes"
          },
          "tags" => [
            "demo",
            "environment",
            "preview"
          ],
          "notes" => "Sanitized example for paging and category-filter demonstrations; no real credentials."
      } ],
      [ "generic", {
          "schema" => "vault.generic.v1",
          "title" => "Example License Key",
          "username" => "license_demo",
          "password" => "demo-generic-secret-not-real",
          "url" => "https://licenses.example.test",
          "tags" => [
            "demo",
            "generic",
            "license"
          ],
          "notes" => "Fake custom-secret example for pagination and category filters."
      } ],
      [ "generic", {
          "schema" => "vault.generic.v1",
          "title" => "Webhook Signing Example",
          "username" => "webhook_demo",
          "password" => "demo-generic-secret-not-real",
          "url" => "https://hooks.example.test",
          "tags" => [
            "demo",
            "generic",
            "webhook"
          ],
          "notes" => "Fake custom-secret example for pagination and category filters."
      } ],
      [ "generic", {
          "schema" => "vault.generic.v1",
          "title" => "Sandbox Integration Secret",
          "username" => "integration_demo",
          "password" => "demo-generic-secret-not-real",
          "url" => "https://integrations.example.test",
          "tags" => [
            "demo",
            "generic",
            "integration"
          ],
          "notes" => "Fake custom-secret example for pagination and category filters."
      } ],
      [ "generic", {
          "schema" => "vault.generic.v1",
          "title" => "Sample Service Credential",
          "username" => "service_demo",
          "password" => "demo-generic-secret-not-real",
          "url" => "https://services.example.test",
          "tags" => [
            "demo",
            "generic",
            "service"
          ],
          "notes" => "Fake custom-secret example for pagination and category filters."
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
        item.update!(favorite: true) if [ "Acme Analytics", "Demo PostgreSQL" ].include?(payload.fetch("title"))

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
