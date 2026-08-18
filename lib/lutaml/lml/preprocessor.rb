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
        expand_lines(input_file.read, base_dir, [])
      end

      private

      def base_dir
        input_file.is_a?(StringIO) ? Dir.pwd : File.dirname(input_file.path)
      end

      def expand_lines(text, base_dir, chain)
        text.split(/\r?\n/)
            .flat_map { |line| expand_line(line, base_dir, chain) }
            .join("\n")
      end

      def expand_line(line, base_dir, chain)
        cleaned = strip_comment(line)
        path = include_path(cleaned, base_dir)
        return [cleaned] unless path

        raise Error, "circular include detected: #{path}" if chain.include?(path)

        expand_lines(read_included(path), File.dirname(path), chain + [path])
      end

      def include_path(line, base_dir)
        match = line.match(/^\s*include\s+(.+)/)
        return nil unless match

        File.expand_path(match[1].strip, base_dir)
      end

      def read_included(path)
        File.read(path)
      rescue Errno::ENOENT, Errno::EACCES => e
        warn "Skipping #{path}: #{e.message}" # TODO.refactor/09: raise
        ""
      end

      def strip_comment(line)
        line.sub(%r{//.*}, "")
      end
    end
  end
end
