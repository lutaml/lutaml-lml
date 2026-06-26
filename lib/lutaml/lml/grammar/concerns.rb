# frozen_string_literal: true

module Lutaml
  module Lml
    module Grammar
      module Concerns
        autoload :Primitives, "lutaml/lml/grammar/concerns/primitives"
        autoload :Attributes, "lutaml/lml/grammar/concerns/attributes"
        autoload :Associations, "lutaml/lml/grammar/concerns/associations"
        autoload :Definitions, "lutaml/lml/grammar/concerns/definitions"
        autoload :ViewRules, "lutaml/lml/grammar/concerns/view_rules"
        autoload :InstanceRules, "lutaml/lml/grammar/concerns/instance_rules"
        autoload :DataStructures, "lutaml/lml/grammar/concerns/data_structures"
      end
    end
  end
end
