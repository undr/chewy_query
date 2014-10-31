require 'spec_helper'

describe ChewyQuery::Builder::Nodes::MatchAll do
  describe '#__render__' do
    def render(&block)
      ChewyQuery::Builder::Filters.new(&block).__render__
    end

    specify{ expect(render{ match_all }).to eq(match_all: {}) }
  end
end
