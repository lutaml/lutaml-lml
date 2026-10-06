# frozen_string_literal: true

module Lutaml
  module Lml
    class Preprocessor
      attr_reader :input_file

      def initialize(input_file)
        @input_file = Source.wrap(input_file)
      end

      class << self
        def call(input_file)
          new(input_file).call
        end
      end

      def call
        expand_lines(@input_file.read, @input_file.base_dir, [])
      end

      private

      # Comments (`//`, `/* */`) are consumed by the grammar's trivia
      # skip (parsanol-ruby#134); only include directives are expanded
      # here. Line structure is preserved so parse-error positions
      # match the source.
      def expand_lines(text, base_dir, chain)
        validate_block_comments(text)
        text.split(/\r?\n/)
            .flat_map { |line| expand_line(line, base_dir, chain) }
            .join("\n")
      end

      def expand_line(line, base_dir, chain)
        path = include_path(line, base_dir)
        return [line] unless path

        raise Error, "circular include detected: #{path}" if chain.include?(path)

        expand_lines(read_included(path), File.dirname(path), chain + [path])
      end

      def include_path(line, base_dir)
        match = line.match(/^\s*include\s+(.+)$/)
        return nil unless match

        File.expand_path(trim_trailing_comment(match[1].strip), base_dir)
      end

      def trim_trailing_comment(path)
        path.sub(%r{\s+(//|/\*).*}, '')
      end

      def read_included(path)
        File.read(path, encoding: 'UTF-8')
      rescue Errno::ENOENT, Errno::EACCES => e
        raise Error, "cannot read include #{path}: #{e.message}"
      end

      # Quote-aware scan: a `/*` opened outside a string literal or a
      # line comment must close before end of input. The grammar's
      # trivia would otherwise reject the text with an unrelated
      # expected-token error.
      def validate_block_comments(text)
        quote = nil
        pos = 0
        open_index = nil
        while pos < text.length
          ch = text[pos]
          if quote
            if ch == '\\'
              pos += 2
              next
            end
            quote = nil if ch == quote
          elsif open_index
            if text[pos, 2] == '*/'
              open_index = nil
              pos += 1
            end
          elsif ['"', "'"].include?(ch)
            quote = ch
          elsif text[pos, 2] == '//'
            pos = text.index("\n", pos) || text.length
            next
          elsif text[pos, 2] == '/*'
            open_index = pos
          end
          pos += 1
        end
        return unless open_index

        line = text[0...open_index].count("\n") + 1
        raise Error, "unterminated block comment at line #{line}"
      end
    end
  end
end
