class AuditEventsController < ApplicationController
  def index
    result = Audit::ListEvents.call(
      user: Current.user,
      action: params[:event_action],
      category: params[:category],
      range: params[:range],
      outcome: params[:outcome],
      page: params[:page],
      request: request
    )
    @events = result.events
    # One ownership-scoped query for this page; never infer access from an old audit.
    item_ids = @events.filter_map { |event| event.vault_item_id if event.action.start_with?("vault_item.") }.uniq
    @linked_vault_item_ids = Current.user.vault_items.where(id: item_ids).pluck(:id).to_set
    @pagy = result.pagy
    @page = result.page
    @total = result.total
    @total_pages = result.total_pages
    @available_actions = result.available_actions
    @all_actions = result.all_actions
    @action_filter = result.selected_action
    @available_categories = result.available_categories
    @category_filter = result.selected_category
    @category_counts = result.category_counts
    @selected_range = result.selected_range
    @selected_outcome = result.selected_outcome
    @range_options = result.range_options
    @outcome_options = result.outcome_options
    @summary_total = result.summary_total
    @summary_sensitive = result.summary_sensitive
    @summary_failed = result.summary_failed
    @summary_latest_at = result.summary_latest_at
  end
end
