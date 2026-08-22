# frozen_string_literal: true

require "parslet"
require "parslet/convenience"

module Lutaml
  module Lml
    # The Parslet parser: raw LML text → parse tree. Pipeline-level
    # entry points live on the Lutaml::Lml module (parse /
    # parse_document).
    class Parser < Parslet::Parser
      include Grammar::Full

      root(:diagram)
    end
  end
end
