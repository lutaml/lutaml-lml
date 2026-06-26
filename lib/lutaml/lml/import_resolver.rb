# frozen_string_literal: true

require "set"

module Lutaml
  module Lml
    class ImportResolver
      def initialize(base_path)
        @base_path = base_path
      end

      def resolve(document)
        entities = {}
        associations = []
        visited = Set.new

        document.view_imports.each do |import|
          resolve_import(import.path, entities, associations, visited, @base_path)
        end

        collect_local_entities(document, entities, associations)

        [entities.values, associations]
      end

      private

      def resolve_import(path, entities, associations, visited, base_path)
        base_dir = base_path ? File.dirname(base_path) : Dir.pwd
        abs_pattern = File.expand_path(path, base_dir)

        Dir.glob(abs_pattern).each do |file_path|
          next if visited.include?(file_path)
          visited.add(file_path)

          if view_file?(file_path)
            resolve_view_file(file_path, entities, associations, visited)
          else
            resolve_model_file(file_path, entities, associations)
          end
        end
      end

      def resolve_view_file(file_path, entities, associations, visited)
        doc = Parser.parse_document(File.new(file_path))

        collect_local_entities(doc, entities, associations)

        doc.view_imports&.each do |import|
          resolve_import(import.path, entities, associations, visited, file_path)
        end
      rescue Errno::ENOENT, Errno::EACCES => e
        warn "Skipping #{file_path}: #{e.message}"
        []
      end

      def resolve_model_file(file_path, entities, associations)
        content = File.read(file_path)
        wrapped = "diagram Fragment {\n#{content}\n}"
        doc = Parser.parse_document(StringIO.new(wrapped))

        collect_local_entities(doc, entities, associations)
      rescue Errno::ENOENT, Errno::EACCES => e
        warn "Skipping #{file_path}: #{e.message}"
        []
      end

      def view_file?(file_path)
        head = File.read(file_path, 200, encoding: "UTF-8")
        head.match?(/\b(view|diagram)\s+\w/)
      rescue Errno::ENOENT, Errno::EACCES
        false
      end

      def collect_local_entities(doc, entities, associations)
        merge_entities(doc.classes, entities)
        merge_entities(doc.enums, entities)
        merge_entities(doc.data_types, entities)
        associations.concat(doc.associations.to_a)
      end

      def merge_entities(collection, entities)
        collection.each do |entity|
          entities[entity.name] ||= entity
        end
      end
    end
  end
end
