# frozen_string_literal: true

require_relative "core"
require_relative "instances"

module Lutaml
  module Lml
    module Grammar
      module Full
        include Core
        include Instances
      end
    end
  end
end
