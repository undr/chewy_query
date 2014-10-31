require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Missing do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ !name }).to eq(missing: { field: 'name', existence: true, null_value: false }) }
    specify{ expect(render{ !name? }).to eq(missing: { field: 'name', existence: true, null_value: true }) }
    specify{ expect(render{ name == nil }).to eq(missing: { field: 'name', existence: false, null_value: true }) }
    specify{ expect(render{ ~!name }).to eq(missing: { field: 'name', existence: true, null_value: false }) }
  end
end
