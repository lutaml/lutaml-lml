# frozen_string_literal: true

require 'json'
require 'parsanol'
# parsanol/parg does not require the parsanol core itself; both are
# needed before the compiler builds atoms.
require 'parsanol/parg'

module Lutaml
  module Lml
    # LML grammar: the PARG source (grammar/lml.parg) is the single
    # source of truth; grammar/lml.artifact.json is its compiled form
    # (regenerate with `rake parg`). Loading the committed artifact
    # costs ~4ms where compiling the text costs ~500ms, so the
    # artifact is the preferred path; its embedded source binds it to
    # the .parg, and a drifted or missing artifact falls back to
    # compiling (the sync spec keeps the pair honest in CI).
    module Grammar
      ENTRY = 'diagram'
      GRAMMAR_PATH = File.expand_path('grammar/lml.parg', __dir__)
      ARTIFACT_PATH = File.expand_path('grammar/lml.artifact.json', __dir__)

      def self.artifact
        @artifact ||= load_artifact || compile_artifact
      end

      def self.load_artifact
        return unless File.exist?(ARTIFACT_PATH)

        envelope = JSON.parse(File.read(ARTIFACT_PATH))
        return unless envelope['source'] == File.read(GRAMMAR_PATH)

        Parsanol::PARG::Artifact.new(envelope, ARTIFACT_PATH, File.dirname(ARTIFACT_PATH))
      end

      def self.compile_artifact
        document = Parsanol::PARG::Parser.new(File.read(GRAMMAR_PATH)).parse
        Parsanol::PARG::Artifact.new(
          Parsanol::PARG::Compiler.compile(document).envelope, nil, nil
        )
      end
    end
  end
end
