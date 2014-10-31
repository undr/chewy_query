require 'spec_helper'

describe ChewyQuery::Builder::Nodes::And do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render { name? & (email == 'email') }).to eq(
      and: [{ exists: { field: 'name' } }, { term: { 'email' => 'email' } }]
    ) }
    specify{ expect(render { ~(name? & (email == 'email')) }).to eq(
      and: { filters: [{ exists: { field: 'name' } }, { term: { 'email' => 'email' } }], _cache: true}
    ) }
  end
end
