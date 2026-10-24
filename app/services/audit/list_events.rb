module Audit
  class ListEvents
    Result = Data.define(
      :events, :page, :per_page, :total, :total_pages,
      :available_actions, :all_actions, :selected_action,
      :available_categories, :selected_category, :category_counts, :pagy,
      :selected_range, :selected_outcome, :range_options, :outcome_options,
      :summary_total, :summary_sensitive, :summary_failed, :summary_latest_at
    )

    DEFAULT_PER_PAGE = 10
    MAX_PER_PAGE = 100
    RANGE_OPTIONS = { "7" => "Past 7 days", "30" => "Past 30 days",
                      "90" => "Past 90 days", "all" => "All time" }.freeze
    OUTCOME_OPTIONS = { "completed" => "Completed", "failed" => "Failed",
                        "recorded" => "Recorded" }.freeze

    def self.call(user:, action: nil, category: nil, page: 1, per_page: DEFAULT_PER_PAGE,
                  request: nil, range: nil, outcome: nil)
      new(user:, action:, category:, page:, per_page:, request:, range:, outcome:).call
    end

    def initialize(user:, action:, category:, page:, per_page:, request:, range:, outcome:)
      @user = user
      @action = action.to_s.strip.presence
      @category = category.to_s.strip.presence
      @page = [ page.to_i, 1 ].max
      @per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
      @request = request
      @selected_range = range.to_s.presence_in(RANGE_OPTIONS.keys) || "30"
      @selected_outcome = outcome.to_s.presence_in(OUTCOME_OPTIONS.keys)
    end

    def call
      # This intentionally excludes unattributed sign-in failures and global
      # key-rotation events. They must not be assigned to users by untrusted email.
      account_scope = user.audit_events
      base_scope = account_scope.order(created_at: :desc, id: :desc)
      window_scope = if selected_range == "all"
        account_scope
      else
        account_scope.where(created_at: (Time.current - selected_range.to_i.days)..)
      end

      all_actions = account_scope.reorder(nil).distinct.order(:action).pluck(:action)
      counts = window_scope.group(:action).count
      category_counts = counts.each_with_object(Hash.new(0)) do |(candidate, count), memo|
        memo[AuditEventPresenter.category_for(candidate)] += count
      end.sort.to_h
      available_categories = all_actions.map { |candidate| AuditEventPresenter.category_for(candidate) }.uniq.sort
      selected_category = category.presence_in(available_categories)
      category_actions = selected_category ? all_actions.select { |candidate| AuditEventPresenter.category_for(candidate) == selected_category } : all_actions
      available_actions = category_actions
      selected_action = action.presence_in(available_actions)

      filtered = base_scope
      filtered = filtered.where(created_at: (Time.current - selected_range.to_i.days)..) unless selected_range == "all"
      filtered = filtered.where(action: category_actions) if selected_category
      filtered = filtered.where(action: selected_action) if selected_action
      if selected_outcome
        eligible_actions = AuditEventPresenter.actions_for_outcome(selected_outcome, all_actions)
        filtered = filtered.where(action: eligible_actions)
      end

      total = filtered.count
      total_pages = [ (total.to_f / per_page).ceil, 1 ].max
      current_page = [ page, total_pages ].min
      options = { count: total, page: current_page, limit: per_page }
      options[:request] = Pagy::Request.new(request: request) if request
      pagy = Pagy::Offset.new(**options)

      Result.new(
        events: filtered.offset(pagy.offset).limit(pagy.limit),
        page: current_page, per_page:, total:, total_pages:,
        available_actions:, all_actions:, selected_action:,
        available_categories:, selected_category:, category_counts:, pagy:,
        selected_range:, selected_outcome:, range_options: RANGE_OPTIONS,
        outcome_options: OUTCOME_OPTIONS,
        summary_total: counts.values.sum,
        summary_sensitive: counts.sum { |candidate, count| AuditEventPresenter::SENSITIVE_ACTIONS.include?(candidate) ? count : 0 },
        summary_failed: counts.sum { |candidate, count| AuditEventPresenter.outcome_for(candidate) == "failed" ? count : 0 },
        summary_latest_at: window_scope.maximum(:created_at)
      )
    end

    private

    attr_reader :user, :action, :category, :page, :per_page, :request, :selected_range, :selected_outcome
  end
end
