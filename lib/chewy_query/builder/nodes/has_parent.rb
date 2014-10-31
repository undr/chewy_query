require 'chewy_query/builder/nodes/has_relation'

module ChewyQuery
  class Builder
    module Nodes
      class HasParent < HasRelation
        private
        def _relation
          :has_parent
        end
      end
    end
  end
end
