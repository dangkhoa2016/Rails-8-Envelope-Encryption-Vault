class ErrorsController < ActionController::Base
  layout "error"

  after_action :protect_error_response

  def not_found
    render_error(:not_found, "Page not found", "The page you requested could not be found.")
  end

  def unprocessable_entity
    render_error(:unprocessable_entity, "Request could not be processed", "The request was invalid or is no longer valid. Please try again.")
  end

  def internal_server_error
    render_error(:internal_server_error, "Something went wrong", "We could not complete your request. Please try again shortly.")
  end

  private

  def render_error(status, title, message)
    render :show, status:, locals: { error_title: title, error_message: message }
  end

  def protect_error_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
  end
end
