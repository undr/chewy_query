require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Or do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ name? | (email == 'email') }).to eq(
      or: [{ exists: { field: 'name' } }, { term: { 'email' => 'email' } }]
    ) }
    specify{ expect(render{ ~(name? | (email == 'email')) }).to eq(
      or: { filters: [{ exists: { field: 'name' } }, { term: { 'email' => 'email' } }], _cache: true }
    ) }
  end
end
