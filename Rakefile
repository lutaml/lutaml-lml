# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Compile grammar/lml.parg to the shipped grammar artifact'
task :parg do
  require 'parsanol'
  require 'parsanol/parg'
  require 'json'

  source = File.expand_path('lib/lutaml/lml/grammar/lml.parg', __dir__)
  target = File.expand_path('lib/lutaml/lml/grammar/lml.artifact.json', __dir__)
  document = Parsanol::PARG::Parser.new(File.read(source)).parse
  envelope = Parsanol::PARG::Compiler.compile(document).envelope
  File.write(target, "#{JSON.pretty_generate(envelope)}\n")
  puts "Wrote #{target} (grammar #{envelope.fetch('grammar')}, " \
       "version #{envelope.fetch('version')})"
end

task default: :spec
