# frozen_string_literal: true

module Lutaml
  module Lml
    module Format
      module Adapter
        class StandardAdapter < Document
          TYPE_KEY = "__type__"

          def self.parse(data, _options = {})
            return data if data.is_a?(Hash)

            input = data.is_a?(IO) ? data : StringIO.new(data.to_s)
            doc = Lutaml::Lml.parse_document(input)
            instance_to_hash(doc.instance)
          end

          def to_lml(_options = {})
            attrs = @attributes.dup
            type_name = attrs.delete(TYPE_KEY) || "Data"
            body = hash_to_lml_body(attrs)
            "instance #{type_name} {\n#{body}\n}"
          end

          private

          def self.instance_to_hash(instance)
            return nil unless instance

            hash = {}
            hash[TYPE_KEY] = instance.type if instance.type

            instance.each_attribute do |name, value, nested|
              if nested.any?
                hashes = nested.map { |i| instance_to_hash(i) }
                hash[name] = nested.one? ? hashes.first : hashes
              elsif value.is_a?(Array)
                hash[name] = value.map { |v| primitive_value(v) }
              elsif !value.nil?
                hash[name] = primitive_value(value)
              end
            end

            if instance.instance
              hash.merge!(instance_to_hash(instance.instance))
            end

            hash
          end

          def self.primitive_value(val)
            case val
            when TrueClass, FalseClass then val
            when Integer, Float then val
            else val.to_s
            end
          end

          def hash_to_lml_body(hash, indent = 1)
            lines = []
            prefix = "  " * indent

            hash.each do |key, value|
              next if key == TYPE_KEY

              lines << format_value(prefix, key, value, indent)
            end

            lines.join("\n")
          end

          def format_value(prefix, key, value, indent)
            return "#{prefix}#{key} = ref:(#{value[:reference]})" if reference_value?(value)

            case value
            when Array
              format_array(prefix, key, value, indent)
            when Hash
              format_nested(prefix, key, value, indent)
            when TrueClass, FalseClass, Integer, Float
              "#{prefix}#{key} = #{value}"
            else
              "#{prefix}#{key} = #{quote_value(value)}"
            end
          end

          def format_array(prefix, key, items, indent)
            elements = items.map do |item|
              if reference_value?(item)
                "  ref:(#{item[:reference]})"
              else
                case item
                when Hash
                  format_nested_instance(item, indent + 1)
                else
                  "  #{quote_value(item)}"
                end
              end
            end

            inner = elements.join(",\n")
            "#{prefix}#{key} = [\n#{inner}\n#{prefix}]"
          end

          def format_nested(prefix, key, hash, indent)
            type_name = hash.fetch(TYPE_KEY, "")
            inner = hash_to_lml_body(hash, indent + 1)
            type_clause = type_name.empty? ? "" : " #{type_name}"
            "#{prefix}#{key} = instance#{type_clause} {\n#{inner}\n#{prefix}}"
          end

          def format_nested_instance(hash, indent)
            prefix = "  " * indent
            type_name = hash.fetch(TYPE_KEY, "")
            inner = hash_to_lml_body(hash, indent + 1)
            type_clause = type_name.empty? ? "" : " #{type_name}"
            "#{prefix}instance#{type_clause} {\n#{inner}\n#{prefix}}"
          end

          # RS 3001 par. Value type: a `reference` map is the wire form of a
          # reference literal; it emits as `ref:(path)`, never as a nested
          # instance.
          def reference_value?(value)
            value.is_a?(Hash) && value.keys == [:reference]
          end

          # The grammar's `word` rule is [A-Za-z0-9_] only (lml.parg) and
          # `variable = quoted_string / 1*word` — a bare value is a run of
          # word characters and nothing else. Anything else (a dash, a
          # space, a digit-leading date...) commits the value parser to
          # `number` or fails re-parsing, so it must be emitted quoted.
          # This predicate is the single source of truth for the emit
          # side; the parse side is pinned by the grammar itself.
          BARE_WORD = /\A\w+\z/.freeze

          def quote_value(val)
            return val.to_s if val.is_a?(Numeric) || val.is_a?(TrueClass) || val.is_a?(FalseClass)

            str = val.to_s
            return str if str.match?(BARE_WORD)

            # The grammar has no escape sequences: dq_string runs to the
            # first unescaped ", sq_string to the first '. Pick a quote
            # character the value does not contain so the emit re-parses.
            unless str.include?('"')
              return "\"#{str}\""
            end
            unless str.include?("'")
              return "'#{str}'"
            end

            raise Lutaml::Lml::Error,
                  "cannot emit #{str.inspect}: the LML string syntax has no " \
                  "escapes and the value contains both quote kinds"
          end
        end
      end
    end
  end
end
