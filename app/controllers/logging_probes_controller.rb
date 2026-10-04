class LoggingProbesController < ActionController::Base
  protect_from_forgery with: :null_session

  def create
    head :no_content
  end
end
