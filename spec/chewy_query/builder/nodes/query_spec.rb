require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Query do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ q(query_string: { query: 'name: hello' }) }).to eq(
      query: { query_string: { query: 'name: hello' } }
    ) }

    specify{ expect(render{ ~q(query_string: { query: 'name: hello' }) }).to eq(
      fquery: { query: { query_string: { query: 'name: hello' } }, _cache: true }
    ) }
  end
end
