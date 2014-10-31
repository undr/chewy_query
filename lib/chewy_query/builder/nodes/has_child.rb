require 'chewy_query/builder/nodes/has_relation'

module ChewyQuery
  class Builder
    module Nodes
      class HasChild < HasRelation
        private
        def _relation
          :has_child
        end
      end
    end
  end
end
