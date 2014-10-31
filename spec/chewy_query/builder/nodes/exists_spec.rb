require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Exists do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ name? }).to eq(exists: { field: 'name' }) }
    specify{ expect(render{ !!name? }).to eq(exists: { field: 'name' }) }
    specify{ expect(render{ !!name }).to eq(exists: { field: 'name' }) }
    specify{ expect(render{ name != nil }).to eq(exists: { field: 'name' }) }
    specify{ expect(render{ !(name == nil) }).to eq(exists: { field: 'name' }) }
    specify{ expect(render{ ~name? }).to eq(exists: { field: 'name' }) }
  end
end
