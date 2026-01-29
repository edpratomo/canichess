ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

if ! ENV["RAILS_MASTER_KEY"] && ENV["RAILS_MASTER_KEY_FILE"]
  ENV["RAILS_MASTER_KEY"] = File.read(ENV["RAILS_MASTER_KEY_FILE"]).strip
end

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
