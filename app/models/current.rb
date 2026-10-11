class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request_id
  delegate :user, to: :session, allow_nil: true
end
