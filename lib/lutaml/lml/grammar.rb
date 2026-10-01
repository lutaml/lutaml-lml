# frozen_string_literal: true

# parsanol/parg does not require the parsanol core itself; both are
# needed before the compiler builds atoms.
require 'parsanol'
require 'parsanol/parg'

module Lutaml
  module Lml
    # LML grammar: the PARG source (grammar/lml.parg) compiled in memory
    # to a parsanol artifact. The .parg text is the single source of
    # truth; parsing runs native-first with the Ruby engine as fallback.
    module Grammar
      ENTRY = 'diagram'
      GRAMMAR_PATH = File.expand_path('grammar/lml.parg', __dir__)

      def self.artifact
        @artifact ||= begin
          document = Parsanol::PARG::Parser.new(File.read(GRAMMAR_PATH)).parse
          Parsanol::PARG::Artifact.new(
            Parsanol::PARG::Compiler.compile(document).envelope, nil, nil
          )
        end
      end
    end
  end
end
