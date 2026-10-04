class KeyRegistry < ApplicationRecord
  STATUSES = %w[pending active decrypt_only retired].freeze
  validates :provider, :kek_id, presence: true
  validates :status, inclusion: { in: STATUSES }
end
