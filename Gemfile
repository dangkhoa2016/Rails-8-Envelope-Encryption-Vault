source "https://rubygems.org"

# Production baseline is pinned by .ruby-version. Keep a narrow compatibility
# range so CI can exercise Ruby 4.0 without changing the production runtime.
ruby ">= 3.4", "< 4.1"

gem "rails", "8.1.4"
# Pin the patched DNS resolver separately from the Ruby runtime.
gem "resolv", ">= 0.7.2"
gem "pg", "~> 1.6"
gem "puma", ">= 5.0"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.4"
gem "bcrypt", "~> 3.1"
gem "rack-attack", "~> 6.8"
gem "pagy", "~> 43.8.1"
gem "aws-sdk-kms", "~> 1"
gem "solid_cache"
gem "bootsnap", require: false
gem "kamal", require: false
# Avoid vulnerable net-ssh versions pulled in transitively by Kamal/SSHKit.
gem "net-ssh", "~> 7.3", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.49"
end

group :development do
  gem "web-console"
end
