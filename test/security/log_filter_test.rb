require "test_helper"

class LogFilterTest < ActiveSupport::TestCase
  test "vault plaintext fields are filtered" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    values = {
      title: "Sensitive title",
      q: "Sensitive title fragment",
      username: "secret-user",
      secret_value: "canary-password",
      notes: "private note",
      env_text: "API_KEY=canary",
      token: "123456"
    }
    filtered = filter.filter(values)
    values.each_key { |key| assert_equal "[FILTERED]", filtered[key] }
  end
end
