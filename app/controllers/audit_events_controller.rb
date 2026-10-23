class AuditEventsController < ApplicationController
  def index
    result = Audit::ListEvents.call(
      user: Current.user,
      action: params[:event_action],
      category: params[:category],
      page: params[:page],
      request: request
    )
    @events = result.events
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
  end
end
