# frozen_string_literal: true

module Lutaml
  module Formatter
    autoload :Base, "lutaml/lml/formatter/base"
    autoload :Graphviz, "lutaml/lml/formatter/graphviz"
    autoload :Elk, "lutaml/lml/formatter/elk"
  end
end
