# frozen_string_literal: true

require 'thor'
require 'pathname'
require 'lutaml/lml'

module Lutaml
  module Cli
    # Thor CLI commands for LutaML DSL generation and validation.
    class LmlCommands < Thor
      include ::Lutaml::Lml::HasAttributes

      SUPPORTED_FORMATS = %w[yaml lutaml exp].freeze
      DEFAULT_INPUT_FORMAT = 'lutaml'
      DEFAULT_OUTPUT_FORMAT = 'svg'

      EXTENSION_FORMAT_MAP = {
        '.svg' => 'svg', '.svgz' => 'svgz',
        '.png' => 'png', '.gif' => 'gif', '.jpg' => 'jpg', '.jpeg' => 'jpeg',
        '.pdf' => 'pdf', '.ps' => 'ps', '.eps' => 'eps',
        '.dot' => 'dot', '.xdot' => 'xdot',
        '.fig' => 'fig', '.json' => 'json',
        '.imap' => 'imap', '.cmapx' => 'cmapx'
      }.freeze

      PARSE_HANDLERS = {
        'lutaml' => ->(path) { Lutaml::Lml::Parser.parse(File.new(path)) },
        'yaml' => ->(path) { Lutaml::Lml::YamlParser.parse(path.to_s) },
        'yml' => ->(path) { Lutaml::Lml::YamlParser.parse(path.to_s) },
        'exp' => lambda { |path|
          require 'lutaml/express'
          Lutaml::Express::Parsers::Exp.parse(File.new(path))
        }
      }.freeze

      FORMATTER_ATTR_TARGETS = %i[graph edge node].freeze

      def initialize(*args)
        super
        @formatter = ::Lutaml::Formatter::Graphviz.new if defined?(::Lutaml::Formatter::Graphviz)
        @out_object = $stdout
      end

      desc 'generate [PATHS]', 'Generate diagram output from LutaML DSL files'
      long_desc <<-DESC
        Generate diagram output from one or more LutaML DSL files.

        Supports multiple input formats (lutaml, yaml, exp) and can output
        to various formats (svg, png, dot, pdf, etc.).

        Examples:
          lutaml lml generate model.lutaml -o diagram.svg

          lutaml lml generate model.lutaml -o diagram.dot -t dot

          lutaml lml generate model.lutaml project.lutaml -o output/
      DESC
      method_option :output, type: :string, aliases: '-o',
                             desc: 'Output path (file or directory)'
      method_option :formatter, type: :string, aliases: '-f',
                                desc: 'Output formatter (default: graphviz)'
      method_option :type, type: :string, aliases: '-t',
                           desc: 'Output format type (svg, png, dot, etc.)'
      method_option :input_format, type: :string, aliases: '-i',
                                   desc: 'Input format (lutaml, yaml, exp)'
      method_option :graph, type: :string, aliases: '-g',
                            desc: 'Graph attributes (key=value,key2=value2)'
      method_option :edge, type: :string, aliases: '-e',
                           desc: 'Edge attributes (key=value,key2=value2)'
      method_option :node, type: :string, aliases: '-n',
                           desc: 'Node attributes (key=value,key2=value2)'
      method_option :all, type: :string, aliases: '-a',
                          desc: 'Set attributes for graph, edge, and node'
      def generate(*paths)
        assert_input_paths(paths)

        setup_options
        @paths = paths.map { |path| Pathname.new(path) }

        assert_output_path

        @paths.each { |input_path| process_single_file(input_path) }
      end

      desc 'validate [PATHS]', 'Validate LutaML DSL syntax'
      long_desc <<-DESC
        Validate the syntax of one or more LutaML DSL files.

        Checks for syntax errors and structural issues in the DSL files
        without generating output.

        Examples:
          lutaml lml validate model.lutaml

          lutaml lml validate model.lutaml project.lutaml
      DESC
      def validate(*paths)
        assert_input_paths(paths)
        errors = paths.map { |p| validate_single_file(p) }.compact
        report_validation(errors)
      end

      desc 'compile PATH', 'Compile LML model definitions into Ruby classes'
      long_desc <<-DESC
        Parse an LML file containing model definitions and compile them
        into Ruby classes that can be used to instantiate and validate data.

        The compiled classes are anonymous Serializable subclasses registered
        in the ModelCompiler. With --namespace, classes are also registered
        as constants in the given module.

        Examples:
          lutaml lml compile models.lml

          lutaml lml compile models.lml --namespace MyModels
      DESC
      method_option :namespace, type: :string, aliases: '-n',
                             desc: 'Register compiled classes in a module'
      def compile(path)
        raise Thor::Error, "File does not exist: #{path}" unless File.exist?(path)

        ns = options[:namespace] ? resolve_namespace(options[:namespace]) : nil
        result = Lutaml::Lml::ModelCompiler.new(namespace: ns).compile(File.new(path))

        result.each_key do |name|
          say "  compiled: #{name}", :green
        end
        say "\n#{result.size} class(es) compiled", :green
      end

      no_commands do
        def resolve_namespace(name)
          name.split('::').reduce(Object) do |mod, const_name|
            mod.const_get(const_name)
          end
        rescue NameError
          raise Thor::Error, "Namespace '#{name}' not found"
        end

        def assert_input_paths(paths)
          return unless paths.empty?

          raise Thor::Error,
                'No input files provided. Please specify at least ' \
                'one .lutaml file.'
        end

        def assert_output_path
          return unless @output_path&.file? && @paths.length > 1

          raise Thor::Error,
                'Output path must be a directory if multiple input files ' \
                'are given'
        end

        def process_single_file(input_path)
          raise Thor::Error, "File does not exist: #{input_path}" unless input_path.exist?

          document = parse_document(input_path)
          result = @formatter.format(document)
          write_output(input_path, result)
        end

        def resolve_output_path(input_path)
          return @out_object unless @output_path

          path = @output_path
          path = path.join("#{input_path.basename('.*')}.#{@formatter.type}") if path.directory?
          path
        end

        def write_output(input_path, result)
          target = resolve_output_path(input_path)
          if target.is_a?(Pathname)
            target.open('w+') { |f| f.write(result) }
            say "Generated: #{target}", :green
          else
            target.puts(result)
          end
        end

        def validate_single_file(path_string)
          input_path = Pathname.new(path_string)
          return report_file_error(input_path, 'File does not exist') unless input_path.exist?

          parse_document(input_path)
          say "✓ #{input_path}", :green
          nil
        rescue StandardError => e
          report_file_error(input_path, e.message)
        end

        def report_file_error(input_path, message)
          say "✗ #{input_path}: #{message}", :red
          "#{input_path}: #{message}"
        end

        def report_validation(errors)
          if errors.any?
            say "\nValidation failed with #{errors.size} error(s)", :red
            exit 1
          else
            say "\nAll files valid!", :green
          end
        end

        def parse_document(input_path)
          handler = PARSE_HANDLERS[@input_format]
          return handler.call(input_path) if handler

          raise Thor::Error, "Unsupported input format: #{@input_format}"
        end

        def setup_options
          @formatter = options[:formatter] if options[:formatter]
          @output_path = Pathname.new(options[:output]) if options[:output]
          @input_format = options[:input_format] || DEFAULT_INPUT_FORMAT
          @type = resolve_output_type

          setup_formatter_options
        end

        def resolve_output_type
          return options[:type] if options[:type]
          return DEFAULT_OUTPUT_FORMAT unless @output_path

          ext = @output_path.extname.downcase
          EXTENSION_FORMAT_MAP.fetch(ext, DEFAULT_OUTPUT_FORMAT)
        end

        def parse_kv_string(str)
          str.split(',').to_h do |pair|
            key, value = pair.split('=', 2)
            [key.strip, value&.strip]
          end
        end

        def apply_kv_to_formatter(option_key, str)
          targets = option_key == :all ? FORMATTER_ATTR_TARGETS : [option_key]
          parse_kv_string(str).each do |key, value|
            targets.each { |t| @formatter.public_send(t)[key] = value }
          end
        end

        def setup_formatter_options
          return unless @formatter

          @formatter.type = @type if @type

          FORMATTER_ATTR_TARGETS.each do |target|
            apply_kv_to_formatter(target, options[target]) if options[target]
          end
          apply_kv_to_formatter(:all, options[:all]) if options[:all]
        end
      end

      def self.exit_on_failure?
        true
      end
    end
  end
end
