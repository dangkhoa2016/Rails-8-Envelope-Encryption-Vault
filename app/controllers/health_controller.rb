class HealthController < ActionController::Base
  def ready
    ActiveRecord::Base.connection.select_value("SELECT 1")
    provider = KeyProviders::Registry.fetch
    provider.verify_key! if provider.respond_to?(:verify_key!)
    provider.assert_write_allowed! if provider.respond_to?(:assert_write_allowed!)
    head :ok
  rescue StandardError => e
    Rails.logger.warn("readiness.failed error_class=#{e.class}")
    head :service_unavailable
  end
end
