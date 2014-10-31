require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Raw do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ r(term: { name: 'name' }) }).to eq(term: { name: 'name' }) }
  end
end
