module Vault
  class ListItems
    Result = Data.define(:summaries, :page, :per_page, :total, :total_pages, :tags_by_item_id, :available_tags, :pagy)

    DEFAULT_PER_PAGE = 6
    MAX_PER_PAGE = 100

    def self.call(user:, q: nil, kind: nil, status: nil, favorite: nil, tag: nil, page: 1, per_page: DEFAULT_PER_PAGE, request: nil)
      new(user:, q:, kind:, status:, favorite:, tag:, page:, per_page:, request:).call
    end

    def initialize(user:, q:, kind:, status:, favorite:, tag:, page:, per_page:, request:)
      @user = user
      @q = q.to_s.strip.first(200)
      @kind = kind.to_s.presence_in(VaultItem::KINDS)
      @status = status.to_s.presence_in(%w[active archived all]) || "active"
      @favorite = ActiveModel::Type::Boolean.new.cast(favorite)
      @tag = tag.to_s.strip.first(80)
      @page = [ page.to_i, 1 ].max
      @per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
      @request = request
    end

    def call
      scope = candidate_scope

      # With no private title/tag search, let PostgreSQL count and paginate.
      # Only decrypt the six items on the requested page (or a bounded
      # caller-selected page size). This also bounds AWS KMS unwrap requests.
      #
      # A private title/tag search must inspect all matching encrypted
      # candidates: intentionally do NOT truncate results at 250 items.
      # Such searches are O(number of candidate secrets); an encrypted
      # searchable index would be a separate, explicitly reviewed design.
      searching_encrypted_fields = q.present? || tag.present?
      if searching_encrypted_fields
        decrypted = scope.map { |item| summary_for(item) }
        available_tags = tag_suggestions(decrypted)
        decrypted = decrypted.select { |_, title, _| title_matches?(title) } if q.present?
        decrypted = decrypted.select { |_, _, tags| tag_matches?(tags) } if tag.present?
        total = decrypted.length
      else
        total = scope.count
      end

      total_pages = [ (total.to_f / per_page).ceil, 1 ].max
      current_page = [ page, total_pages ].min
      options = { count: total, page: current_page, limit: per_page }
      if request
        options[:request] = Pagy::Request.new(request: request)
        # URL state is a controller-generated allowlist. Never include decrypted
        # titles or user-created tag values in page links.
        options[:querify] = ->(query_params) { query_params.delete_if { |key, _| !%w[page filter kind status favorite].include?(key) } }
      end
      pager = Pagy::Offset.new(**options)
      paged = if searching_encrypted_fields
        decrypted.slice(pager.offset, pager.limit) || []
      else
        scope.offset(pager.offset).limit(pager.limit).map { |item| summary_for(item) }
      end
      # Suggestions on an unfiltered page are intentionally page-local; a
      # free-text tag field below allows any tag, including tags on other pages.
      available_tags ||= tag_suggestions(paged)

      Result.new(
        summaries: paged.map { |item, title, _| [ item, title ] },
        page: current_page,
        per_page: per_page,
        total: total,
        total_pages: total_pages,
        tags_by_item_id: paged.to_h { |item, _, tags| [ item.id, tags ] },
        available_tags: available_tags,
        pagy: pager
      )
    end

    def tag_suggestions(summaries)
      summaries.flat_map { |_, _, tags| tags }.uniq.sort_by(&:downcase)
    end

    private

    attr_reader :user, :q, :kind, :status, :favorite, :tag, :page, :per_page, :request

    def candidate_scope
      scope = user.vault_items.includes(:current_version).order(favorite: :desc, updated_at: :desc)
      scope = scope.where(kind: kind) if kind
      scope = scope.where(archived_at: nil) if status == "active"
      scope = scope.where.not(archived_at: nil) if status == "archived"
      scope = scope.where(favorite: true) if favorite
      scope
    end

    def summary_for(item)
      payload = Vault::RevealItem.call(user: user, item: item, audit: false)
      tags = Array(payload["tags"]).filter_map { |value| value.to_s.strip.presence }.uniq.first(12)
      [ item, payload["title"].presence || "Untitled", tags ]
    rescue Crypto::Error, ArgumentError
      [ item, "[Unable to decrypt]", [] ]
    ensure
      payload = nil
    end

    def title_matches?(title)
      title.downcase.include?(q.downcase)
    end

    def tag_matches?(tags)
      tags.any? { |candidate| candidate.casecmp?(tag) }
    end
  end
end
