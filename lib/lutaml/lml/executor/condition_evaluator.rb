# frozen_string_literal: true

module Lutaml
  module Lml
    class Executor
      # Evaluates collection validation conditions against instance data.
      #
      # Conditions are simple DSL strings like "count >= 3" or
      # "all? { |i| i.components.count > 0 }". The evaluator parses a safe
      # subset of forms — it never calls `eval` on arbitrary Ruby.
      #
      # Supported condition forms:
      #   "count >= N"                      — collection size comparison
      #   "count == N", "count <= N", etc.
      #   "all? { |i| i.path OP literal }"  — every instance matches
      #   "any? { |i| i.path OP literal }"  — at least one instance matches
      #
      # The block predicate supports a single comparison of an instance
      # attribute path (e.g. `i.components.count`, `i.name`) against a
      # literal (number, quoted string, true/false/nil) using one of
      # `>, >=, <, <=, ==, !=`.
      #
      class ConditionEvaluator
        ConditionError = Class.new(StandardError)

        BLOCK_FORM = /\A\s*(all|any)\?\s*\{\s*\|(\w+)\|\s*(.+?)\s*\}\s*\z/
        COMPARISON = /\A\s*(.+?)\s*(>=|<=|==|!=|>|<)\s*(.+?)\s*\z/

        # Evaluate all validation conditions against a collection of instances.
        # Returns an array of error strings (empty if all pass).
        def self.evaluate(collection, instances)
          return [] unless collection.validations&.any?
          return [] unless collection.is_a?(Collection)

          new(instances).evaluate_all(collection.validations)
        end

        def initialize(instances)
          @instances = instances
        end

        def evaluate_all(conditions)
          conditions.filter_map do |condition|
            evaluate(condition)
          rescue ConditionError => e
            "Validation failed: #{e.message}"
          end
        end

        private

        def evaluate(condition)
          return evaluate_block(condition) if condition.match?(/\A\s*(all|any)\?\s*\{/)
          return evaluate_count(condition) if condition.match?(/\bcount\s*[<>=]+/)

          raise ConditionError, "Unsupported condition: #{condition}"
        end

        def evaluate_count(condition)
          match = condition.match(/\bcount\s*(>=|<=|==|>|<)\s*(\d+)/)
          raise ConditionError, "Invalid count condition: #{condition}" unless match

          operator = match[1]
          expected = match[2].to_i
          actual = @instances.length

          compare(actual, operator, expected) ||
            raise(ConditionError, "#{condition} (got #{actual})")
          nil
        end

        def evaluate_block(condition)
          form = condition.match(BLOCK_FORM)
          raise ConditionError, "Invalid block condition: #{condition}" unless form

          quantifier = form[1]
          predicate = form[3]

          comparator = build_predicate(predicate)
          satisfied = @instances.public_send("#{quantifier}?") do |instance|
            comparator.call(instance)
          end

          return nil if satisfied

          raise ConditionError, "#{condition} (failed for #{quantifier == "all" ? "at least one" : "all"} instance)"
        end

        # Parses a single comparison predicate "i.path OP literal" into a
        # callable that, given an instance, returns true/false.
        def build_predicate(predicate)
          match = predicate.match(COMPARISON)
          raise ConditionError, "Unsupported predicate: #{predicate}" unless match

          lhs = match[1]
          operator = match[2]
          rhs = match[3]

          getter = attribute_getter(lhs)
          expected = parse_literal(rhs)

          lambda do |instance|
            actual = getter.call(instance)
            compare(actual, operator, expected)
          rescue NoMethodError
            false
          end
        end

        # Parses "i.attr.subattr..." into a callable on an instance.
        def attribute_getter(path)
          parts = path.strip.split(".")
          raise ConditionError, "Invalid attribute path: #{path}" if parts.empty?

          unless parts.first == "i"
            raise ConditionError, "Block predicate must reference i: #{path}"
          end

          chain = parts.drop(1)
          lambda do |instance|
            chain.reduce(instance) { |receiver, method| receiver.public_send(method) }
          end
        end

        # Parses a single literal value from the predicate RHS.
        def parse_literal(token)
          stripped = token.strip
          case stripped
          when /\A-?\d+\z/              then stripped.to_i
          when /\A-?\d+\.\d+\z/         then stripped.to_f
          when /\A".*"\z/, /\A'.*'\z/   then stripped[1..-2]
          when "true"                   then true
          when "false"                  then false
          when "nil", "null"            then nil
          else
            raise ConditionError, "Unsupported literal: #{token}"
          end
        end

        def compare(actual, operator, expected)
          case operator
          when ">=" then actual.to_f >= expected.to_f
          when "<=" then actual.to_f <= expected.to_f
          when "==" then actual == expected
          when "!=" then actual != expected
          when ">"  then actual.to_f > expected.to_f
          when "<"  then actual.to_f < expected.to_f
          else false
          end
        end
      end
    end
  end
end
