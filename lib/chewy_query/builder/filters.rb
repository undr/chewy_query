require 'chewy_query/builder/nodes/base'
require 'chewy_query/builder/nodes/expr'
require 'chewy_query/builder/nodes/field'
require 'chewy_query/builder/nodes/bool'
require 'chewy_query/builder/nodes/and'
require 'chewy_query/builder/nodes/or'
require 'chewy_query/builder/nodes/not'
require 'chewy_query/builder/nodes/raw'
require 'chewy_query/builder/nodes/exists'
require 'chewy_query/builder/nodes/missing'
require 'chewy_query/builder/nodes/range'
require 'chewy_query/builder/nodes/prefix'
require 'chewy_query/builder/nodes/regexp'
require 'chewy_query/builder/nodes/equal'
require 'chewy_query/builder/nodes/query'
require 'chewy_query/builder/nodes/script'
require 'chewy_query/builder/nodes/has_child'
require 'chewy_query/builder/nodes/has_parent'
require 'chewy_query/builder/nodes/match_all'

module ChewyQuery
  class Builder
    # Context provides simplified DSL functionality for filters declaring.
    # You can use logic operations <tt>&</tt> and <tt>|</tt> to concat
    # expressions.
    #
    #   builder.filter{ (article.title =~ /Honey/) & (age < 42) & !rate }
    #
    #
    class Filters
      def initialize(outer = nil, &block)
        @block = block
        @outer = outer || eval('self', block.binding)
      end

      # Outer scope call
      # Block evaluates in the external context
      #
      #   def name
      #     'Friend'
      #   end
      #
      #   builder.filter{ name == o{ name } } # => {filter: {term: {name: 'Friend'}}}
      #
      def o(&block)
        @outer.instance_exec(&block)
      end

      # Returns field node
      # Used if method_missing is not working by some reason.
      # Additional expression options might be passed as second argument hash.
      #
      #   builder.filter{ f(:name) == 'Name' } == builder.filter{ name == 'Name' } # => true
      #   builder.filter{ f(:name, execution: :bool) == ['Name1', 'Name2'] } ==
      #     builder.filter{ name(execution: :bool) == ['Name1', 'Name2'] } # => true
      #
      # Supports block for getting field name from the outer scope
      #
      #   def field
      #     :name
      #   end
      #
      #   builder.filter{ f{ field } == 'Name' } == builder.filter{ name == 'Name' } # => true
      #
      def f(name = nil, *args, &block)
        name = block ? o(&block) : name
        Nodes::Field.new(name, *args)
      end

      # Returns script filter
      # Just script filter. Supports additional params.
      #
      #   builder.filter{ s('doc["num1"].value > 1') }
      #   builder.filter{ s('doc["num1"].value > param1', param1: 42) }
      #
      # Supports block for getting script from the outer scope
      #
      #   def script
      #     'doc["num1"].value > param1 || 1'
      #   end
      #
      #   builder.filter{ s{ script } } == builder.filter{ s('doc["num1"].value > 1') } # => true
      #   builder.filter{ s(param1: 42) { script } } == builder.filter{ s('doc["num1"].value > 1', param1: 42) } # => true
      #
      def s(*args, &block)
        params = args.extract_options!
        script = block ? o(&block) : args.first
        Nodes::Script.new(script, params)
      end

      # Returns query filter
      #
      #   builder.filter{ q(query_string: {query: 'name: hello'}) }
      #
      # Supports block for getting query from the outer scope
      #
      #   def query
      #     {query_string: {query: 'name: hello'}}
      #   end
      #
      #   builder.filter{ q{ query } } == builder.filter{ q(query_string: {query: 'name: hello'}) } # => true
      #
      def q(query = nil, &block)
        Nodes::Query.new(block ? o(&block) : query)
      end

      # Returns raw expression
      # Same as filter with arguments instead of block, but can participate in expressions
      #
      #   builder.filter{ r(term: {name: 'Name'}) }
      #   builder.filter{ r(term: {name: 'Name'}) & (age < 42) }
      #
      # Supports block for getting raw filter from the outer scope
      #
      #   def filter
      #     {term: {name: 'Name'}}
      #   end
      #
      #   builder.filter{ r{ filter } } == builder.filter{ r(term: {name: 'Name'}) } # => true
      #   builder.filter{ r{ filter } } == builder.filter(term: {name: 'Name'}) # => true
      #
      def r(raw = nil, &block)
        Nodes::Raw.new(block ? o(&block) : raw)
      end

      # Bool filter chainable methods
      # Used to create bool query. Nodes are passed as arguments.
      #
      #   builder.filter{ must(age < 42, name == 'Name') }
      #   builder.filter{ should(age < 42, name == 'Name') }
      #   builder.filter{ must(age < 42).should(name == 'Name1', name == 'Name2') }
      #   builder.filter{ should_not(age >= 42).must(name == 'Name1') }
      #
      %w(must must_not should).each do |method|
        define_method method do |*exprs|
          Nodes::Bool.new.send(method, *exprs)
        end
      end

      # Initializes has_child filter.
      # Chainable interface acts the same as main query interface. You can pass plain
      # filters or plain queries or filter with DSL block.
      #
      #   builder.filter{ has_child('user').filter(term: {role: 'Admin'}) }
      #   builder.filter{ has_child('user').filter{ role == 'Admin' } }
      #   builder.filter{ has_child('user').query(match: {name: 'borogoves'}) }
      #
      # Filters and queries might be combined and filter_mode and query_mode are configurable:
      #
      #   builder.filter do
      #     has_child('user')
      #       .filter{ name: 'Peter' }
      #       .query(match: {name: 'Peter'})
      #       .filter{ age > 42 }
      #       .filter_mode(:or)
      #   end
      #
      def has_child(type)
        Nodes::HasChild.new(type, @outer)
      end

      # Initializes has_parent filter.
      # Chainable interface acts the same as main query interface. You can pass plain
      # filters or plain queries or filter with DSL block.
      #
      #   builder.filter{ has_parent('user').filter(term: {role: 'Admin'}) }
      #   builder.filter{ has_parent('user').filter{ role == 'Admin' } }
      #   builder.filter{ has_parent('user').query(match: {name: 'borogoves'}) }
      #
      # Filters and queries might be combined and filter_mode and query_mode are configurable:
      #
      #   builder.filter do
      #     has_parent('user')
      #       .filter{ name: 'Peter' }
      #       .query(match: {name: 'Peter'})
      #       .filter{ age > 42 }
      #       .filter_mode(:or)
      #   end
      #
      def has_parent(type)
        Nodes::HasParent.new(type, @outer)
      end

      # Just simple match_all filter.
      #
      def match_all
        Nodes::MatchAll.new
      end

      # Creates field or exists node
      # Additional options for further expression might be passed as hash
      #
      #   builder.filter{ name == 'Name' } == builder.filter(term: {name: 'Name'}) # => true
      #   builder.filter{ name? } == builder.filter(exists: {term: 'name'}) # => true
      #   builder.filter{ name(execution: :bool) == ['Name1', 'Name2'] } ==
      #     builder.filter(terms: {name: ['Name1', 'Name2'], execution: :bool}) # => true
      #
      # Also field names might be chained to use dot-notation for ES field names
      #
      #   builder.filter{ article.title =~ 'Hello' }
      #   builder.filter{ article.tags? }
      #
      def method_missing(method, *args, &block)
        method = method.to_s
        if method =~ /\?\Z/
          Nodes::Exists.new(method.gsub(/\?\Z/, ''))
        else
          f(method, *args)
        end
      end

      # Evaluates context block, returns top node.
      # For internal usage.
      #
      def __result__
        instance_exec(&@block)
      end

      # Renders evaluated filters.
      # For internal usage.
      #
      def __render__
        __result__.__render__ # haha, wtf?
      end
    end
  end
end
