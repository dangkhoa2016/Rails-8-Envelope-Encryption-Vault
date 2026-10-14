require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "rejects passwords above bcrypt 72 byte boundary" do
    password = "ổ" * 40 # 80 UTF-8 bytes although only 40 characters
    user = User.new(email_address: "bytes@example.test", password: password, password_confirmation: password)
    refute user.valid?
    assert user.errors[:password].any? { |message| message.include?("72 bytes") }
  end
end
