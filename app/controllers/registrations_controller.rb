class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  before_action :require_signups_enabled

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      AuditEvent.create!(user: @user, action: "user.registered", metadata: {})
      redirect_to root_path, notice: "Account created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_signups_enabled
    head :not_found unless ENV.fetch("ALLOW_SIGNUPS", "false") == "true"
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
