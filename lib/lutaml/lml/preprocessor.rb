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

      # RS 3001 §Comment: `//` to end of line and `/* ... */` block
      # comments are stripped quote-aware before include expansion, so
      # string literals (e.g. URLs) survive intact.
      def expand_lines(text, base_dir, chain)
        text = strip_comments(text)
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
        match = line.match(/^\s*include\s+(.+)/)
        return nil unless match

        File.expand_path(match[1].strip, base_dir)
      end

      def read_included(path)
        File.read(path, encoding: "UTF-8")
      rescue Errno::ENOENT, Errno::EACCES => e
        raise Error, "cannot read include #{path}: #{e.message}"
      end

      def strip_comments(text)
        scanner = CommentScanner.new(text)
        out = +""
        until scanner.done?
          scanner.emit(out)
        end
        out
      end

      # Quote-aware scanner removing `//` and `/* */` comments while
      # preserving string literals and line structure.
      class CommentScanner
        def initialize(text)
          @text = text
          @pos = 0
          @quote = nil
        end

        def done?
          @pos >= @text.length
        end

        def emit(out)
          return emit_quoted(out) if @quote
          return emit_delimiter(out) if string_delimiter?(@text[@pos])
          return emit_block_comment(out) if block_comment_start?
          return skip_line_comment if line_comment_start?

          out << @text[@pos]
          @pos += 1
        end

        private

        def string_delimiter?(ch)
          ch == '"' || ch == "'"
        end

        def emit_delimiter(out)
          @quote = @text[@pos]
          out << @text[@pos]
          @pos += 1
        end

        def emit_quoted(out)
          ch = @text[@pos]
          out << ch
          if ch == "\\"
            out << @text[@pos + 1].to_s
            @pos += 2
          else
            @quote = nil if ch == @quote
            @pos += 1
          end
        end

        def block_comment_start?
          @text[@pos, 2] == "/*"
        end

        def emit_block_comment(out)
          close = @text.index("*/", @pos + 2)
          raise Lutaml::Lml::Error, "unterminated block comment" unless close

          out << "\n" * @text[@pos...close].count("\n") << " "
          @pos = close + 2
        end

        def line_comment_start?
          @text[@pos, 2] == "//"
        end

        def skip_line_comment
          @pos = @text.index("\n", @pos) || @text.length
        end
      end
    end
  end
end
