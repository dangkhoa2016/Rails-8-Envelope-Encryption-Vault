class ErrorProbesController < ActionController::Base
  def unprocessable_entity
    raise ActionController::InvalidAuthenticityToken, "FIX42 controlled 422 probe"
  end

  def internal_server_error
    raise "FIX42 controlled 500 probe"
  end
end
