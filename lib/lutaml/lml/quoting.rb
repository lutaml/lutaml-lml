# frozen_string_literal: true

module Lutaml
  module Lml
    # The single source of truth for scalar quoting on the emit side:
    # bare only for runs of [A-Za-z0-9_] (the grammar's word rule);
    # double quotes with the two RS 3001 escapes otherwise. Values,
    # attribute keys, and the canonical form all emit through here.
    module Quoting
      BARE_WORD = /\A\w+\z/

      module_function

      # @param scalar [String, #to_s]
      # @return [String] the emitted form: parseable back to scalar
      def quote_scalar(scalar)
        str = scalar.to_s
        return str if str.match?(BARE_WORD)

        quote_always(str)
      end

      # Double-quoted form even when the scalar is a bare word. Used
      # where the grammar only accepts quoted strings (definitions,
      # requires, instance data values, wire names).
      #
      # @param scalar [String, #to_s]
      # @return [String] the double-quoted, escaped form
      def quote_always(scalar)
        escaped = scalar.to_s.gsub('\\') { |bs| bs * 2 }.gsub('"') { |q| "\\#{q}" }
        "\"#{escaped}\""
      end
    end
  end
end
