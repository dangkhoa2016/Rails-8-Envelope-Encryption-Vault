module Audit
  class ListEvents
    Result = Data.define(
      :events,
      :page,
      :per_page,
      :total,
      :total_pages,
      :available_actions,
      :selected_action,
      :available_categories,
      :selected_category,
      :category_counts,
      :pagy
    )

    DEFAULT_PER_PAGE = 10
    MAX_PER_PAGE = 100

    def self.call(user:, action: nil, category: nil, page: 1, per_page: DEFAULT_PER_PAGE, request: nil)
      new(user:, action:, category:, page:, per_page:, request:).call
    end

    def initialize(user:, action:, category:, page:, per_page:, request:)
      @user = user
      @action = action.to_s.strip.presence
      @category = category.to_s.strip.presence
      @page = [ page.to_i, 1 ].max
      @per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
      @request = request
    end

    def call
      base_scope = user.audit_events.order(created_at: :desc, id: :desc)
      available_actions = user.audit_events.reorder(nil).distinct.order(:action).pluck(:action)
      action_counts = user.audit_events.reorder(nil).group(:action).count
      category_counts = action_counts.each_with_object(Hash.new(0)) do |(candidate, count), memo|
        memo[AuditEventPresenter.category_for(candidate)] += count
      end.sort.to_h
      available_categories = action_counts.keys.map { |candidate| AuditEventPresenter.category_for(candidate) }.uniq.sort
      selected_category = category.presence_in(available_categories)
      category_actions =
        if selected_category == "Other"
          available_actions.reject { |candidate| AuditEventPresenter.category_for(candidate) != "Other" }
        elsif selected_category
          AuditEventPresenter.actions_for_category(selected_category)
        else
          []
        end
      actions_for_filter = selected_category ? available_actions.select { |candidate| category_actions.include?(candidate) } : available_actions
      selected_action = action.presence_in(actions_for_filter)

      filtered_scope = base_scope
      filtered_scope = filtered_scope.where(action: category_actions) if selected_category
      filtered_scope = filtered_scope.where(action: selected_action) if selected_action

      total = filtered_scope.count
      total_pages = [ (total.to_f / per_page).ceil, 1 ].max
      current_page = [ page, total_pages ].min
      options = { count: total, page: current_page, limit: per_page }
      options[:request] = Pagy::Request.new(request: request) if request
      pager = Pagy::Offset.new(**options)

      Result.new(
        events: filtered_scope.offset(pager.offset).limit(pager.limit),
        page: current_page,
        per_page: per_page,
        total:,
        total_pages:,
        available_actions: actions_for_filter,
        selected_action:,
        available_categories:,
        selected_category:,
        category_counts:,
        pagy: pager
      )
    end

    private

    attr_reader :user, :action, :category, :page, :per_page, :request
  end
end
