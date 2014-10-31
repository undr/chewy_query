require 'spec_helper'

describe ChewyQuery::Builder::Nodes::Prefix do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ name =~ 'nam' }).to eq(prefix: { 'name' => 'nam' }) }
    specify{ expect(render{ name !~ 'nam' }).to eq(not: { prefix: { 'name' => 'nam' } }) }
    specify{ expect(render{ ~name =~ 'nam' }).to eq(prefix: { 'name' => 'nam', _cache: true }) }
    specify{ expect(render{ ~name !~ 'nam' }).to eq(not: { prefix: { 'name' => 'nam', _cache: true } }) }
    specify{ expect(render{ name(cache: false) =~ 'nam' }).to eq(prefix: { 'name' => 'nam', _cache: false }) }
  end
end
