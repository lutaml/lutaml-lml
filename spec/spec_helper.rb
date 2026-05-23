# frozen_string_literal: true

require "bundler/setup"
require "lutaml/lml"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixtures_path(path)
  File.join(File.expand_path("./fixtures", __dir__), path)
end

def by_name(entries, name)
  entries.detect { |n| n.name == name }
end
