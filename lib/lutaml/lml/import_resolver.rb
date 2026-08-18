# frozen_string_literal: true

require "set"

module Lutaml
  module Lml
    class ImportResolver
      def initialize(base_dir)
        @base_dir = base_dir
      end

      def resolve(document)
        entities = {}
        associations = []
        visited = Set.new

        document.view_imports.each do |import|
          resolve_import(import.path, entities, associations, visited, @base_dir)
        end

        collect_local_entities(document, entities, associations)

        [entities.values, associations]
      end

      private

      def resolve_import(path, entities, associations, visited, base_dir)
        abs_pattern = File.expand_path(path, base_dir)

        Dir.glob(abs_pattern).each do |file_path|
          next if visited.include?(file_path)
          visited.add(file_path)

          doc = parse_file(file_path)
          collect_local_entities(doc, entities, associations)

          doc.view_imports.each do |import|
            resolve_import(import.path, entities, associations, visited, File.dirname(file_path))
          end
        end
      end

      # The grammar root accepts every file shape (diagram, view,
      # models block, bare definitions) — no content sniffing needed.
      def parse_file(file_path)
        File.open(file_path) { |file| Pipeline.call(file, resolve: false) }
      rescue Errno::ENOENT, Errno::EACCES => e
        warn "Skipping #{file_path}: #{e.message}" # TODO.refactor/09: raise
        Document.new
      end

      def collect_local_entities(doc, entities, associations)
        EntityTypes.all.each do |type|
          merge_entities(doc.public_send(type.entity_type), entities)
        end
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
