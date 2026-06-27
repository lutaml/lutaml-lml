# frozen_string_literal: true

module Lutaml
  module Lml
    class Preprocessor
      attr_reader :input_file

      def initialize(input_file)
        @input_file = input_file
      end

      class << self
        def call(input_file)
          new(input_file).call
        end
      end

      def call
        input_file.rewind
        include_root = input_file.is_a?(StringIO) ? Dir.pwd : File.dirname(input_file.path)
        input_file.read.split("\n").reduce([]) do |res, line|
          res.push(*process_dsl_line(include_root, line))
        end.join("\n")
      end

      private

      def process_dsl_line(include_root, line)
        process_include_line(include_root, process_comment_line(line))
      end

      def process_comment_line(line)
        has_comment = line.match(%r{//.*})
        return line if has_comment.nil?

        line.gsub(%r{//.*}, "")
      end

      def process_include_line(include_root, line)
        include_path_match = line.match(/^\s*include\s+(.+)/)
        return line if include_path_match.nil?

        path_to_file = File.expand_path(include_path_match[1].strip, include_root)
        File.read(path_to_file).split("\n").map do |l|
          process_comment_line(l)
        end
      rescue Errno::ENOENT
        $stderr.puts(
          "No such file or directory @ rb_sysopen - #{path_to_file}, " \
          "include file paths need to be supplied relative to the main document"
        )
        []
      end
    end
  end
end
