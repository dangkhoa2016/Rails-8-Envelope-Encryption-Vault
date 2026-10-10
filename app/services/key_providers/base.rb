module KeyProviders
  class Base
    def provider_name = raise(NotImplementedError)
    def active_key_id = raise(NotImplementedError)
    def assert_write_allowed! = true
    def verify_key!(key_id = active_key_id) = raise(NotImplementedError)
    def wrap_key(dek:, context:) = raise(NotImplementedError)
    def unwrap_key(wrapped_key:, key_id:, context:) = raise(NotImplementedError)
  end
end
