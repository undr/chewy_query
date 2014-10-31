module ChewyQuery
  class Builder
    module Nodes
      class MatchAll < Expr
        def __render__
          { match_all: {} }
        end
      end
    end
  end
end
