class Session < ApplicationRecord
  belongs_to :user

  scope :active, -> { where(revoked_at: nil).where("absolute_expires_at IS NULL OR absolute_expires_at > ?", Time.current) }

  def idle_expired?(at = Time.current)
    seen = last_seen_at || created_at
    seen && seen < at - Rails.configuration.x.security.session_idle_timeout
  end

  def absolute_expired?(at = Time.current)
    absolute_expires_at.present? && absolute_expires_at <= at
  end

  def expired?(at = Time.current)
    revoked_at.present? || idle_expired?(at) || absolute_expired?(at)
  end

  def active?(at = Time.current)
    !expired?(at)
  end

  def touch_activity!(at = Time.current)
    return if last_seen_at && last_seen_at > at - Rails.configuration.x.security.session_touch_interval
    update_column(:last_seen_at, at)
  end

  def recently_reauthenticated?(at = Time.current)
    reauthenticated_at.present? && reauthenticated_at >= at - Rails.configuration.x.security.reauthentication_window
  end

  def mark_reauthenticated!(at = Time.current)
    update_column(:reauthenticated_at, at)
  end

  def revoke!(at = Time.current)
    update_column(:revoked_at, at)
  end
end
