module Settings
  class SessionsController < ApplicationController
    def index
      @sessions = Current.user.sessions.order(created_at: :desc)
    end

    def destroy
      record = Current.user.sessions.find(params[:id])
      record.revoke!
      if record == Current.session
        terminate_session
        redirect_to new_session_path, notice: "Session revoked."
      else
        redirect_to settings_sessions_path, notice: "Session revoked."
      end
    end
  end
end
