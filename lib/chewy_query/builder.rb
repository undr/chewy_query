require 'chewy_query/builder/criteria'
require 'chewy_query/builder/filters'

module ChewyQuery
  # Builder allows you to create ES search requests with convenient
  # chainable DSL. Queries are lazy evaluated and might be merged.
  #
  #   builder = ChewyQuery::Builder.new(:users, types: ['admin', 'manager', 'user'])
  #   builder.filter{ age < 42 }.query(text: {name: 'Alex'}).limit(20)
  #   builder = ChewyQuery::Builder.new(:users, types: 'admin')
  #   builder.filter{ age < 42 }.query(text: {name: 'Alex'}).limit(20)
  #
  class Builder
    attr_reader :index, :options, :criteria

    def initialize(index, options = {})
      @index, @options = index, options
      @types = Array.wrap(options.delete(:types))
      @criteria = Criteria.new(options)
      reset
    end

    # Comparation with other query or collection
    # If other is collection - search request is executed and
    # result is used for comparation
    #
    #   builder.filter(term: {name: 'Johny'}) == builder.filter(term: {name: 'Johny'}) # => true
    #   builder.filter(term: {name: 'Johny'}) == builder.filter(term: {name: 'Johny'}).to_a # => true
    #   builder.filter(term: {name: 'Johny'}) == builder.filter(term: {name: 'Winnie'}) # => false
    #
    def ==(other)
      super || if other.is_a?(self.class)
        other.criteria == criteria
      else
        to_a == other
      end
    end

    # Adds <tt>explain</tt> parameter to search request.
    #
    #   builder.filter(term: {name: 'Johny'}).explain
    #   builder.filter(term: {name: 'Johny'}).explain(true)
    #   builder.filter(term: {name: 'Johny'}).explain(false)
    #
    # Calling explain without any arguments sets explanation flag to true.
    #
    #   builder.filter(term: {name: 'Johny'}).explain
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-explain.html
    #
    def explain(value = nil)
      chain{ criteria.update_request_options explain: (value.nil? ? true : value) }
    end

    # Adds <tt>version</tt> parameter to search request.
    #
    #   builder.filter(term: {name: 'Johny'}).version
    #   builder.filter(term: {name: 'Johny'}).version(true)
    #   builder.filter(term: {name: 'Johny'}).version(false)
    #
    # Calling version without any arguments sets version flag to true.
    #
    #   builder.filter(term: {name: 'Johny'}).version
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-version.html
    #
    def version(value = nil)
      chain{ criteria.update_request_options version: (value.nil? ? true : value) }
    end

    # Sets query compilation mode for search request.
    # Not used if only one filter for search is specified.
    # Possible values:
    #
    # * <tt>:must</tt>
    #   Default value. Query compiles into a bool <tt>must</tt> query.
    #
    #   Ex:
    #
    #     builder.query(text: {name: 'Johny'}).query(range: {age: {lte: 42}})
    #       # => {body: {
    #              query: {bool: {must: [{text: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #            }}
    #
    # * <tt>:should</tt>
    #   Query compiles into a bool <tt>should</tt> query.
    #
    #   Ex:
    #
    #     builder.query(text: {name: 'Johny'}).query(range: {age: {lte: 42}}).query_mode(:should)
    #       # => {body: {
    #              query: {bool: {should: [{text: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #            }}
    #
    # * Any acceptable <tt>minimum_should_match</tt> value (1, '2', '75%')
    #   Query compiles into a bool <tt>should</tt> query with <tt>minimum_should_match</tt> set.
    #
    #   Ex:
    #
    #     builder.query(text: {name: 'Johny'}).query(range: {age: {lte: 42}}).query_mode('50%')
    #       # => {body: {
    #              query: {bool: {
    #                should: [{text: {name: 'Johny'}}, {range: {age: {lte: 42}}}],
    #                minimum_should_match: '50%'
    #              }}
    #            }}
    #
    # * <tt>:dis_max</tt>
    #   Query compiles into a <tt>dis_max</tt> query.
    #
    #   Ex:
    #
    #     builder.query(text: {name: 'Johny'}).query(range: {age: {lte: 42}}).query_mode(:dis_max)
    #       # => {body: {
    #              query: {dis_max: {queries: [{text: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #            }}
    #
    # * Any Float value (0.0, 0.7, 1.0)
    #   Query compiles into a <tt>dis_max</tt> query with <tt>tie_breaker</tt> option set.
    #
    #   Ex:
    #
    #     builder.query(text: {name: 'Johny'}).query(range: {age: {lte: 42}}).query_mode(0.7)
    #       # => {body: {
    #              query: {dis_max: {
    #                queries: [{text: {name: 'Johny'}}, {range: {age: {lte: 42}}}],
    #                tie_breaker: 0.7
    #              }}
    #            }}
    #
    # Default value for <tt>:query_mode</tt> might be changed
    # with <tt>ChewyQuery.query_mode</tt> config option.
    #
    #   ChewyQuery.query_mode = :dis_max
    #   ChewyQuery.query_mode = '50%'
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-dis-max-query.html
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-bool-query.html
    #
    def query_mode(value)
      chain{ criteria.update_options query_mode: value }
    end

    # Sets query compilation mode for search request.
    # Not used if only one filter for search is specified.
    # Possible values:
    #
    # * <tt>:and</tt>
    #   Default value. Filter compiles into an <tt>and</tt> filter.
    #
    #   Ex:
    #
    #     builder.filter{ name == 'Johny' }.filter{ age <= 42 }
    #       # => {body: {query: {filtered: {
    #              query: {...},
    #              filter: {and: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}
    #            }}}}
    #
    # * <tt>:or</tt>
    #   Filter compiles into an <tt>or</tt> filter.
    #
    #   Ex:
    #
    #     builder.filter{ name == 'Johny' }.filter{ age <= 42 }.filter_mode(:or)
    #       # => {body: {query: {filtered: {
    #              query: {...},
    #              filter: {or: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}
    #            }}}}
    #
    # * <tt>:must</tt>
    #   Filter compiles into a bool <tt>must</tt> filter.
    #
    #   Ex:
    #
    #     builder.filter{ name == 'Johny' }.filter{ age <= 42 }.filter_mode(:must)
    #       # => {body: {query: {filtered: {
    #              query: {...},
    #              filter: {bool: {must: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #            }}}}
    #
    # * <tt>:should</tt>
    #   Filter compiles into a bool <tt>should</tt> filter.
    #
    #   Ex:
    #
    #     builder.filter{ name == 'Johny' }.filter{ age <= 42 }.filter_mode(:should)
    #       # => {body: {query: {filtered: {
    #              query: {...},
    #              filter: {bool: {should: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #            }}}}
    #
    # * Any acceptable <tt>minimum_should_match</tt> value (1, '2', '75%')
    #   Filter compiles into bool <tt>should</tt> filter with <tt>minimum_should_match</tt> set.
    #
    #   Ex:
    #
    #     builder.filter{ name == 'Johny' }.filter{ age <= 42 }.filter_mode('50%')
    #       # => {body: {query: {filtered: {
    #              query: {...},
    #              filter: {bool: {
    #                should: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}],
    #                minimum_should_match: '50%'
    #              }}
    #            }}}}
    #
    # Default value for <tt>:filter_mode</tt> might be changed
    # with <tt>ChewyQuery.filter_mode</tt> config option.
    #
    #   ChewyQuery.filter_mode = :should
    #   ChewyQuery.filter_mode = '50%'
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-and-filter.html
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-bool-filter.html
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-or-filter.html
    #
    def filter_mode(value)
      chain{ criteria.update_options filter_mode: value }
    end

    # Acts the same way as `filter_mode`, but used for `post_filter`.
    # Note that it fallbacks by default to `ChewyQuery.filter_mode` if
    # `ChewyQuery.post_filter_mode` is nil.
    #
    #   builder.post_filter{ name == 'Johny' }.post_filter{ age <= 42 }.post_filter_mode(:and)
    #   builder.post_filter{ name == 'Johny' }.post_filter{ age <= 42 }.post_filter_mode(:should)
    #   builder.post_filter{ name == 'Johny' }.post_filter{ age <= 42 }.post_filter_mode('50%')
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-and-filter.html
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-bool-filter.html
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-or-filter.html
    #
    def post_filter_mode(value)
      chain{ criteria.update_options post_filter_mode: value }
    end

    # Sets elasticsearch <tt>size</tt> search request param
    # Default value is set in the elasticsearch and is 10.
    #
    #  builder.filter{ name == 'Johny' }.limit(100)
    #     # => {body: {
    #            query: {...},
    #            size: 100
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-from-size.html
    #
    def limit(value)
      chain{ criteria.update_request_options size: Integer(value) }
    end

    # Sets elasticsearch <tt>from</tt> search request param
    #
    #  builder.filter{ name == 'Johny' }.offset(300)
    #     # => {body: {
    #            query: {...},
    #            from: 300
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-from-size.html
    #
    def offset(value)
      chain{ criteria.update_request_options from: Integer(value) }
    end

    # Elasticsearch highlight query option support
    #
    #   builder.query(...).highlight(fields: { ... })
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-highlighting.html
    #
    def highlight(value)
      chain{ criteria.update_request_options highlight: value }
    end

    # Elasticsearch rescore query option support
    #
    #   builder.query(...).rescore(query: { ... })
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-rescore.html
    #
    def rescore(value)
      chain{ criteria.update_request_options(rescore: value) }
    end

    # Adds facets section to the search request.
    # All the chained facets a merged and added to the
    # search request
    #
    #   builder.facets(tags: {terms: {field: 'tags'}}).facets(ages: {terms: {field: 'age'}})
    #     # => {body: {
    #            query: {...},
    #            facets: {tags: {terms: {field: 'tags'}}, ages: {terms: {field: 'age'}}}
    #          }}
    #
    # If called parameterless - returns result facets from ES performing request.
    # Returns empty hash if no facets was requested or resulted.
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-facets.html
    #
    def facets(params)
      chain{ criteria.update_facets(params) }
    end

    # Adds a script function to score the search request. All scores are
    # added to the search request and combinded according to
    # <tt>boost_mode</tt> and <tt>score_mode</tt>
    #
    #   builder.script_score("doc['boost'].value", filter: { term: {foo: :bar} })
    #       # => {body:
    #              query: {
    #                function_score: {
    #                  query: { ...},
    #                  functions: [{
    #                    script_score: {
    #                       script: "doc['boost'].value"
    #                     },
    #                     filter: { term: { foo: :bar } }
    #                    }
    #                  }]
    #                } } }
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_script_score
    #
    def script_score(script, options = {})
      scoring = options.merge(script_score: { script: script })
      chain{ criteria.update_scores(scoring) }
    end

    # Adds a boost factor to the search request. All scores are
    # added to the search request and combinded according to
    # <tt>boost_mode</tt> and <tt>score_mode</tt>
    #
    # This probably only makes sense if you specifiy a filter
    # for the boost factor as well
    #
    #   builder.boost_factor(23, filter: { term: { foo: :bar} })
    #       # => {body:
    #              query: {
    #                function_score: {
    #                  query: { ...},
    #                  functions: [{
    #                    boost_factor: 23,
    #                    filter: { term: { foo: :bar } }
    #                  }]
    #                } } }
    #
    # @see
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_boost_factor
    #
    def boost_factor(factor, options = {})
      scoring = options.merge(boost_factor: factor.to_i)
      chain{ criteria.update_scores(scoring) }
    end

    # Adds a random score to the search request. All scores are
    # added to the search request and combinded according to
    # <tt>boost_mode</tt> and <tt>score_mode</tt>
    #
    # This probably only makes sense if you specifiy a filter
    # for the random score as well.
    #
    # If you do not pass in a seed value, Time.now will be used
    #
    #   builder.random_score(23, filter: { foo: :bar})
    #       # => {body:
    #              query: {
    #                function_score: {
    #                  query: { ...},
    #                  functions: [{
    #                    random_score: { seed: 23 },
    #                    filter: { foo: :bar }
    #                  }]
    #                } } }
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_random
    #
    def random_score(seed = Time.now, options = {})
      scoring = options.merge(random_score: { seed: seed.to_i })
      chain{ criteria.update_scores(scoring) }
    end

    # Add a field value scoring to the search. All scores are
    # added to the search request and combinded according to
    # <tt>boost_mode</tt> and <tt>score_mode</tt>
    #
    # This function is only available in Elasticsearch 1.2 and
    # greater
    #
    #   builder.field_value_factor(
    #                {
    #                  field: :boost,
    #                  factor: 1.2,
    #                  modifier: :sqrt
    #                }, filter: { foo: :bar})
    #       # => {body:
    #              query: {
    #                function_score: {
    #                  query: { ...},
    #                  functions: [{
    #                    field_value_factor: {
    #                      field: :boost,
    #                      factor: 1.2,
    #                      modifier: :sqrt
    #                    },
    #                    filter: { foo: :bar }
    #                  }]
    #                } } }
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_field_value_factor
    #
    def field_value_factor(settings, options = {})
      scoring = options.merge(field_value_factor: settings)
      chain{ criteria.update_scores(scoring) }
    end

    # Add a decay scoring to the search. All scores are
    # added to the search request and combinded according to
    # <tt>boost_mode</tt> and <tt>score_mode</tt>
    #
    # The parameters have default values, but those may not
    # be very useful for most applications.
    #
    #   builder.decay(
    #                :gauss,
    #                :field,
    #                origin: '11, 12',
    #                scale: '2km',
    #                offset: '5km'
    #                decay: 0.4
    #                filter: { foo: :bar})
    #       # => {body:
    #              query: {
    #                gauss: {
    #                  query: { ...},
    #                  functions: [{
    #                    gauss: {
    #                      field: {
    #                        origin: '11, 12',
    #                        scale: '2km',
    #                        offset: '5km',
    #                        decay: 0.4
    #                      }
    #                    },
    #                    filter: { foo: :bar }
    #                  }]
    #                } } }
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html#_decay_functions
    #
    def decay(function, field, options = {})
      field_options = {
        origin: options.delete(:origin) || 0,
        scale: options.delete(:scale) || 1,
        offset: options.delete(:offset) || 0,
        decay: options.delete(:decay) || 0.1
      }
      scoring = options.merge(function => {
        field => field_options
      })
      chain{ criteria.update_scores(scoring) }
    end

    # Sets elasticsearch <tt>aggregations</tt> search request param
    #
    #  builder.filter{ name == 'Johny' }.aggregations(category_id: {terms: {field: 'category_ids'}})
    #     # => {body: {
    #            query: {...},
    #            aggregations: {
    #              terms: {
    #                field: 'category_ids'
    #              }
    #            }
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-aggregations.html
    #
    def aggregations(params = nil)
      chain{ criteria.update_aggregations params }
    end
    alias :aggs :aggregations

    # Sets elasticsearch <tt>suggest</tt> search request param
    #
    #  builder.suggest(name: {text: 'Joh', term: {field: 'name'}})
    #     # => {body: {
    #            query: {...},
    #            suggest: {
    #              text: 'Joh',
    #              term: {
    #                field: 'name'
    #              }
    #            }
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-suggesters.html
    #
    def suggest(params = nil)
      chain{ criteria.update_suggest params }
    end

    # Marks the criteria as having zero records. This scope  always returns empty array
    # without touching the elasticsearch server.
    # All the chained calls of methods don't affect the result
    #
    #   UsersIndex.none.to_a
    #     # => []
    #   UsersIndex.query(text: {name: 'Johny'}).none.to_a
    #     # => []
    #   UsersIndex.none.query(text: {name: 'Johny'}).to_a
    #     # => []
    def none
      chain{ criteria.update_options(none: true) }
    end

    # Setups strategy for top-level filtered query
    #
    #    builder.filter { name == 'Johny'}.strategy(:leap_frog)
    #     # => {body: {
    #            query: { filtered: {
    #              filter: { term: { name: 'Johny' } },
    #              strategy: 'leap_frog'
    #            } }
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html#_filter_strategy
    #
    def strategy(value = nil)
      chain{ criteria.update_options(strategy: value) }
    end

    # Adds one or more query to the search request
    # Internally queries are stored as an array
    # While the full query compilation this array compiles
    # according to <tt>:query_mode</tt> option value
    #
    # By default it joines inside <tt>must</tt> query
    # See <tt>#query_mode</tt> chainable method for more info.
    #
    #   builder.query(match: {name: 'Johny'}).query(range: {age: {lte: 42}})
    #     # => {body: {
    #            query: {bool: {must: [{match: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}}
    #          }}
    #
    # If only one query was specified, it will become a result
    # query as is, without joining.
    #
    #   builder.query(match: {name: 'Johny'})
    #     # => {body: {
    #            query: {match: {name: 'Johny'}}
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-queries.html
    #
    def query(params)
      chain{ criteria.update_queries(params) }
    end

    # Adds one or more filter to the search request
    # Internally filters are stored as an array
    # While the full query compilation this array compiles
    # according to <tt>:filter_mode</tt> option value
    #
    # By default it joins inside <tt>and</tt> filter
    # See <tt>#filter_mode</tt> chainable method for more info.
    #
    # Also this method supports block DSL.
    # See <tt>ChewyQuery::Builder::Filters</tt> for more info.
    #
    #   builder.filter(term: {name: 'Johny'}).filter(range: {age: {lte: 42}})
    #   builder.filter{ name == 'Johny' }.filter{ age <= 42 }
    #     # => {body: {query: {filtered: {
    #            query: {...},
    #            filter: {and: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}
    #          }}}}
    #
    # If only one filter was specified, it will become a result
    # filter as is, without joining.
    #
    #   builder.filter(term: {name: 'Johny'})
    #     # => {body: {query: {filtered: {
    #            query: {...},
    #            filter: {term: {name: 'Johny'}}
    #          }}}}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-filters.html
    #
    def filter(params = nil, &block)
      params = Filters.new(&block).__render__ if block
      chain{ criteria.update_filters(params) }
    end

    # Adds one or more post_filter to the search request
    # Internally post_filters are stored as an array
    # While the full query compilation this array compiles
    # according to <tt>:post_filter_mode</tt> option value
    #
    # By default it joins inside <tt>and</tt> filter
    # See <tt>#post_filter_mode</tt> chainable method for more info.
    #
    # Also this method supports block DSL.
    # See <tt>ChewyQuery::Builder::Filters</tt> for more info.
    #
    #   builder.post_filter(term: {name: 'Johny'}).post_filter(range: {age: {lte: 42}})
    #   builder.post_filter{ name == 'Johny' }.post_filter{ age <= 42 }
    #     # => {body: {
    #            post_filter: {and: [{term: {name: 'Johny'}}, {range: {age: {lte: 42}}}]}
    #          }}
    #
    # If only one post_filter was specified, it will become a result
    # post_filter as is, without joining.
    #
    #   builder.post_filter(term: {name: 'Johny'})
    #     # => {body: {
    #            post_filter: {term: {name: 'Johny'}}
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-post-filter.html
    #
    def post_filter(params = nil, &block)
      params = Filters.new(&block).__render__ if block
      chain{ criteria.update_post_filters(params) }
    end

    # Sets the boost mode for custom scoring/boosting.
    # Not used if no score functions are specified
    # Possible values:
    #
    # * <tt>:multiply</tt>
    #   Default value. Query score and function result are multiplied.
    #
    #   Ex:
    #
    #     builder.boost_mode('multiply').script_score('doc['boost'].value')
    #       # => {body: {query: function_score: {
    #         query: {...},
    #         boost_mode: 'multiply',
    #         functions: [ ... ]
    #       }}}
    #
    # * <tt>:replace</tt>
    #   Only function result is used, query score is ignored.
    #
    # * <tt>:sum</tt>
    #   Query score and function score are added.
    #
    # * <tt>:avg</tt>
    #   Average of query and function score.
    #
    # * <tt>:max</tt>
    #   Max of query and function score.
    #
    # * <tt>:min</tt>
    #   Min of query and function score.
    #
    # Default value for <tt>:boost_mode</tt> might be changed
    # with <tt>ChewyQuery.score_mode</tt> config option.
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html
    #
    def boost_mode(value)
      chain{ criteria.update_options(boost_mode: value) }
    end

    # Sets the scoring mode for combining function scores/boosts
    # Not used if no score functions are specified.
    # Possible values:
    #
    # * <tt>:multiply</tt>
    #   Default value. Scores are multiplied.
    #
    #   Ex:
    #
    #     builder.score_mode('multiply').script_score('doc['boost'].value')
    #       # => {body: {query: function_score: {
    #         query: {...},
    #         score_mode: 'multiply',
    #         functions: [ ... ]
    #       }}}
    #
    # * <tt>:sum</tt>
    #   Scores are summed.
    #
    # * <tt>:avg</tt>
    #   Scores are averaged.
    #
    # * <tt>:first</tt>
    #   The first function that has a matching filter is applied.
    #
    # * <tt>:max</tt>
    #   Maximum score is used.
    #
    # * <tt>:min</tt>
    #   Minimum score is used
    #
    # Default value for <tt>:score_mode</tt> might be changed
    # with <tt>ChewyQuery.score_mode</tt> config option.
    #
    #   ChewyQuery.score_mode = :first
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-function-score-query.html
    #
    def score_mode(value)
      chain{ criteria.update_options(score_mode: value) }
    end

    # Sets search request sorting
    #
    #   builder.order(:first_name, :last_name).order(age: :desc).order(price: {order: :asc, mode: :avg})
    #     # => {body: {
    #            query: {...},
    #            sort: ['first_name', 'last_name', {age: 'desc'}, {price: {order: 'asc', mode: 'avg'}}]
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-sort.html
    #
    def order(*params)
      chain{ criteria.update_sort(params) }
    end

    # Cleans up previous search sorting and sets the new one
    #
    #   builder.order(:first_name, :last_name).order(age: :desc).reorder(price: {order: :asc, mode: :avg})
    #     # => {body: {
    #            query: {...},
    #            sort: [{price: {order: 'asc', mode: 'avg'}}]
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-sort.html
    #
    def reorder(*params)
      chain{ criteria.update_sort(params, purge: true) }
    end

    # Sets search request field list
    #
    #   builder.only(:first_name, :last_name).only(:age)
    #     # => {body: {
    #            query: {...},
    #            fields: ['first_name', 'last_name', 'age']
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-fields.html
    #
    def only(*params)
      chain{ criteria.update_fields(params) }
    end

    # Cleans up previous search field list and sets the new one
    #
    #   builder.only(:first_name, :last_name).only!(:age)
    #     # => {body: {
    #            query: {...},
    #            fields: ['age']
    #          }}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-request-fields.html
    #
    def only!(*params)
      chain{ criteria.update_fields(params, purge: true) }
    end

    # Specify types participating in the search result
    # Works via <tt>types</tt> filter. Always merged with another filters
    # with the <tt>and</tt> filter.
    #
    #   builder.types(:admin, :manager).filters{ name == 'Johny' }.filters{ age <= 42 }
    #     # => {body: {query: {filtered: {
    #            query: {...},
    #            filter: {and: [
    #              {or: [
    #                {type: {value: 'admin'}},
    #                {type: {value: 'manager'}}
    #              ]},
    #              {term: {name: 'Johny'}},
    #              {range: {age: {lte: 42}}}
    #            ]}
    #          }}}}
    #
    #   builder.types(:admin, :manager).filters{ name == 'Johny' }.filters{ age <= 42 }.filter_mode(:or)
    #     # => {body: {query: {filtered: {
    #            query: {...},
    #            filter: {and: [
    #              {or: [
    #                {type: {value: 'admin'}},
    #                {type: {value: 'manager'}}
    #              ]},
    #              {or: [
    #                {term: {name: 'Johny'}},
    #                {range: {age: {lte: 42}}}
    #              ]}
    #            ]}
    #          }}}}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-type-filter.html
    #
    def types(*params)
      if params.any?
        chain{ criteria.update_types(params) }
      else
        @types
      end
    end

    # Acts the same way as <tt>types</tt>, but cleans up previously set types
    #
    #   builder.types(:admin).types!(:manager)
    #     # => {body: {query: {filtered: {
    #            query: {...},
    #            filter: {type: {value: 'manager'}}
    #          }}}}
    #
    # @see http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/query-dsl-type-filter.html
    #
    def types!(*params)
      chain{ criteria.update_types(params, purge: true) }
    end

    # Merges two queries.
    # Merges all the values in criteria with the same rules as values added manually.
    #
    #   scope1 = builder.filter{ name == 'Johny' }
    #   scope2 = builder.filter{ age <= 42 }
    #   scope3 = builder.filter{ name == 'Johny' }.filter{ age <= 42 }
    #
    #   scope1.merge(scope2) == scope3 # => true
    #
    def merge(other)
      chain{ criteria.merge!(other.criteria) }
    end

    def delete_all_request
      @delete_all_request ||= criteria.delete_all_request_body.merge(index: index_name, type: types)
    end


    def request
      @request ||= criteria.request_body.merge(index: index_name, type: types)
    end

    def inspect
      "#<%s:%#016x @request=%s>" % [self.class, (object_id << 1), request]
    end

    protected

    def reset
      @request, @delete_all_request = nil
    end

    def initialize_clone(other)
      @criteria = other.criteria.clone
      reset
    end

    private

    def index_name
      index.respond_to?(:index_name) ? index.index_name : index
    end

    def chain(&block)
      clone.tap{|q| q.instance_eval(&block) }
    end
  end
end
