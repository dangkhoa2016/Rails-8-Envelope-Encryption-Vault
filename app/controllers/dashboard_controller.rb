class DashboardController < ApplicationController
  def show
    scope = Current.user.vault_items
    @count = scope.count
    @active_count = scope.where(archived_at: nil).count
    @archived_count = scope.where.not(archived_at: nil).count
    @kind_counts = scope.group(:kind).count
    @recent = Vault::ListItems.call(user: Current.user, status: "active", page: 1, per_page: 5).summaries
    @favorites = Vault::ListItems.call(user: Current.user, status: "active", favorite: true, page: 1, per_page: 5).summaries
    @mfa_enabled = Current.user.mfa_enabled?
    @active_session_count = Current.user.sessions.active.count
  end
end
