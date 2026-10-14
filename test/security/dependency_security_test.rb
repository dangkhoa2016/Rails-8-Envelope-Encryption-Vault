require "test_helper"
require "bundler"

class DependencySecurityTest < ActiveSupport::TestCase
  FLOORS = {
    "rails" => "8.1.4",
    "rack" => "3.2.6",
    "rack-attack" => "6.8.0",
    "bcrypt" => "3.1.22",
    "resolv" => "0.7.2"
  }.freeze

  test "security-sensitive dependency floors do not regress" do
    specs = Bundler.locked_gems.specs.index_by(&:name)
    FLOORS.each do |name, floor|
      assert specs[name], "#{name} must be locked"
      assert_operator specs.fetch(name).version, :>=, Gem::Version.new(floor), "#{name} fell below #{floor}"
    end
  end
end
