module ChewyQuery
  class Builder
    module Nodes
      class Bool < Expr
        METHODS = %w(must must_not should)

        def initialize(options = {})
          @options = options
          @must, @must_not, @should = [], [], []
        end

        METHODS.each do |method|
          define_method method do |*exprs|
            instance_variable_get("@#{method}").push(*exprs)
            self
          end
        end

        def __render__
          bool = METHODS.map do |method|
            value = instance_variable_get("@#{method}")
            [method.to_sym, value.map(&:__render__)] if value.any?
          end.compact

          bool = { bool: Hash[bool] }

          bool[:bool][:_cache] = !!@options[:cache] if @options.key?(:cache)
          bool
        end
      end
    end
  end
end
