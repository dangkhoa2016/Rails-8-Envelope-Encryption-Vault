class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request_id, :audit_request_details
  delegate :user, to: :session, allow_nil: true
end
