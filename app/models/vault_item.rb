class VaultItem < ApplicationRecord
  KINDS = %w[login api_key environment database secure_note ssh generic].freeze

  KIND_METADATA = {
    "login" => {
      label: "Login",
      description: "Website or application credentials",
      best_for: "Websites, SaaS accounts, admin portals, and personal sign-ins",
      fields: [ "Username", "Password", "Website URL" ],
      icon: "login",
      accent: "indigo"
    },
    "api_key" => {
      label: "API key",
      description: "API tokens, client secrets, and service credentials",
      best_for: "API tokens, OAuth clients, integration keys, and machine credentials",
      fields: [ "Key / client ID", "Secret", "Service URL" ],
      icon: "code",
      accent: "cyan"
    },
    "environment" => {
      label: "Environment",
      description: "A protected collection of .env variables",
      best_for: "Application configuration, deployment variables, and service settings",
      fields: [ "Environment name", "KEY=VALUE entries" ],
      icon: "terminal",
      accent: "emerald"
    },
    "database" => {
      label: "Database",
      description: "Database host, user, password, and connection details",
      best_for: "PostgreSQL, MySQL, managed databases, and internal data services",
      fields: [ "Host", "Port", "Database", "Username", "Password" ],
      icon: "database",
      accent: "violet"
    },
    "secure_note" => {
      label: "Secure note",
      description: "Private free-form text and recovery information",
      best_for: "Recovery codes, private instructions, license data, and sensitive notes",
      fields: [ "Protected note" ],
      icon: "note",
      accent: "amber"
    },
    "ssh" => {
      label: "Server / SSH",
      description: "SSH login details, passphrases, and server notes",
      best_for: "Linux servers, bastion hosts, SFTP endpoints, and remote administration",
      fields: [ "Server", "SSH port", "Username", "Password / passphrase" ],
      icon: "server",
      accent: "sky"
    },
    "generic" => {
      label: "Custom secret",
      description: "A flexible encrypted secret for anything else",
      best_for: "Secrets that do not fit a dedicated template",
      fields: [ "Identifier", "Secret", "Reference URL" ],
      icon: "lock",
      accent: "slate"
    }
  }.freeze

  belongs_to :user
  has_many :versions, class_name: "VaultItemVersion", dependent: :destroy
  belongs_to :current_version, class_name: "VaultItemVersion", optional: true

  validates :kind, inclusion: { in: KINDS }
  validate :current_version_belongs_to_this_item

  def kind_metadata
    KIND_METADATA.fetch(kind)
  end

  def kind_label
    kind_metadata.fetch(:label)
  end

  private

  def current_version_belongs_to_this_item
    return unless current_version
    return if current_version.vault_item_id == id

    errors.add(:current_version, "must belong to this vault item")
  end
end
