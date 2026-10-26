module Settings
  class SessionsController < ApplicationController
    PER_PAGE = 10

    def index
      owned_sessions = Current.user.sessions
      @total_sessions = owned_sessions.count
      @total_pages = [ (@total_sessions.to_f / PER_PAGE).ceil, 1 ].max
      @page = [ requested_page, @total_pages ].min

      @pagy = Pagy::Offset.new(
        count: @total_sessions,
        page: @page,
        limit: PER_PAGE,
        request: Pagy::Request.new(request: request)
      )
      # Tie-break identical sign-in timestamps to prevent duplicate/missing
      # entries when navigating between pages.
      @sessions = owned_sessions.order(created_at: :desc, id: :desc)
                                .offset(@pagy.offset).limit(@pagy.limit).to_a
    end

    def destroy
      record = Current.user.sessions.find(params[:id])
      record.revoke!
      if record == Current.session
        terminate_session
        redirect_to new_session_path, notice: "Session revoked."
      else
        # Revoked sessions remain visible in the history, and the user should
        # not jump to page one after revoking a session on a later page.
        redirect_to settings_sessions_path(page: requested_page), notice: "Session revoked."
      end
    end

    private

    def requested_page
      raw = params[:page].to_s
      raw.match?(/\A[1-9][0-9]{0,5}\z/) ? raw.to_i : 1
    end
  end
end
