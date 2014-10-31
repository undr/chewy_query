require 'spec_helper'

describe ChewyQuery::Builder do
  subject{ ChewyQuery::Builder.new(:products, types: :product) }

  describe '#==' do
    specify{ expect(subject.query(match: 'hello') == subject.query(match: 'hello')).to be_truthy }
    specify{ expect(subject.query(match: 'hello') == subject.query(match: 'world')).to be_falsy }
    specify{ expect(subject.limit(10) == subject.limit(10)).to be_truthy }
    specify{ expect(subject.limit(10) == subject.limit(11)).to be_falsy }
    specify{ expect(subject.limit(2).limit(10) == subject.limit(10)).to be_truthy }
  end

  describe '#query_mode' do
    specify{ expect(subject.query_mode(:should)).to be_a(described_class) }
    specify{ expect(subject.query_mode(:should)).not_to eq(subject) }
    specify{ expect(subject.query_mode(:should).criteria.options).to include(query_mode: :should) }
    specify{ expect{ subject.query_mode(:should) }.not_to change{ subject.criteria.options } }
  end

  describe '#filter_mode' do
    specify{ expect(subject.filter_mode(:or)).to be_a(described_class) }
    specify{ expect(subject.filter_mode(:or)).not_to eq(subject) }
    specify{ expect(subject.filter_mode(:or).criteria.options).to include(filter_mode: :or) }
    specify{ expect{ subject.filter_mode(:or) }.not_to change{ subject.criteria.options } }
  end

  describe '#post_filter_mode' do
    specify{ expect(subject.post_filter_mode(:or)).to be_a(described_class) }
    specify{ expect(subject.post_filter_mode(:or)).not_to eq(subject) }
    specify{ expect(subject.post_filter_mode(:or).criteria.options).to include(post_filter_mode: :or) }
    specify{ expect{ subject.post_filter_mode(:or) }.not_to change{ subject.criteria.options } }
  end

  describe '#limit' do
    specify{ expect(subject.limit(10)).to be_a(described_class) }
    specify{ expect(subject.limit(10)).not_to eq(subject) }
    specify{ expect(subject.limit(10).criteria.request_options).to include(size: 10) }
    specify{ expect{ subject.limit(10) }.not_to change{ subject.criteria.request_options } }
  end

  describe '#offset' do
    specify{ expect(subject.offset(10)).to be_a(described_class) }
    specify{ expect(subject.offset(10)).not_to eq(subject) }
    specify{ expect(subject.offset(10).criteria.request_options).to include(from: 10) }
    specify{ expect{ subject.offset(10) }.not_to change{ subject.criteria.request_options } }
  end

  describe '#facets' do
    specify{ expect(subject.facets(term: { field: 'hello' })).to be_a(described_class) }
    specify{ expect(subject.facets(term: { field: 'hello' })).not_to eq(subject) }
    specify{ expect(subject.facets(term: { field: 'hello' }).criteria.facets).to include(term: { field: 'hello' }) }
    specify{ expect{ subject.facets(term: { field: 'hello' }) }.not_to change{ subject.criteria.facets } }
  end

  describe '#aggregations' do
    specify{ expect(subject.aggregations(agg1: { field: 'hello' })).to be_a(described_class) }
    specify{ expect(subject.aggregations(agg1: { field: 'hello' })).not_to eq(subject) }
    specify{
      expect(subject.aggregations(agg1: { field: 'hello' }).criteria.aggregations).to include(agg1: { field: 'hello' })
    }
    specify{ expect{ subject.aggregations(agg1: { field: 'hello' }) }.not_to change { subject.criteria.aggregations } }
  end

  describe '#suggest' do
    specify{ expect(subject.suggest(name1: { text: 'hello' })).to be_a(described_class) }
    specify{ expect(subject.suggest(name1: { text: 'hello' })).not_to eq(subject) }
    specify{ expect(subject.suggest(name1: { text: 'hello' }).criteria.suggest).to include(name1: { text: 'hello' }) }
    specify{ expect{ subject.suggest(name1: { text: 'hello' }) }.not_to change{ subject.criteria.suggest } }
  end

  describe '#strategy' do
    specify{ expect(subject.strategy('query_first')).to be_a(described_class) }
    specify{ expect(subject.strategy('query_first')).not_to eq(subject) }
    specify{ expect(subject.strategy('query_first').criteria.options).to include(strategy: 'query_first') }
    specify{ expect{ subject.strategy('query_first') }.not_to change{ subject.criteria.options } }
  end

  describe '#query' do
    specify{ expect(subject.query(match: 'hello')).to be_a(described_class) }
    specify{ expect(subject.query(match: 'hello')).not_to eq(subject) }
    specify{ expect(subject.query(match: 'hello').criteria.queries).to include(match: 'hello') }
    specify{ expect{ subject.query(match: 'hello') }.not_to change{ subject.criteria.queries } }
  end

  describe '#filter' do
    specify{ expect(subject.filter(term: { field: 'hello' })).to be_a(described_class) }
    specify{ expect(subject.filter(term: { field: 'hello' })).not_to eq(subject) }
    specify{ expect{ subject.filter(term: { field: 'hello' }) }.not_to change{ subject.criteria.filters } }
    specify{
      expect(subject.filter(
        [{ term: { field: 'hello' } }, { term: { field: 'world' } }]
      ).criteria.filters).to eq([{ term: { field: 'hello' } }, { term: { field: 'world' } }])
    }

    specify{ expect{ subject.filter{ name == 'John' } }.not_to change{ subject.criteria.filters } }
    specify{ expect(subject.filter{ name == 'John' }.criteria.filters).to eq([{ term: { 'name' => 'John' } }]) }
  end

  describe '#post_filter' do
    specify{ expect(subject.post_filter(term: { field: 'hello' })).to be_a(described_class) }
    specify{ expect(subject.post_filter(term: { field: 'hello' })).not_to eq(subject) }
    specify{ expect{ subject.post_filter(term: { field: 'hello' }) }.not_to change{ subject.criteria.post_filters } }
    specify{
      expect(subject.post_filter(
        [{ term: { field: 'hello' } }, { term: { field: 'world' } }]
      ).criteria.post_filters).to eq([{ term: { field: 'hello' } }, { term: { field: 'world' } }])
    }

    specify{ expect{ subject.post_filter{ name == 'John' } }.not_to change{ subject.criteria.post_filters } }
    specify{
      expect(subject.post_filter{ name == 'John' }.criteria.post_filters).to eq([{ term: { 'name' => 'John' } }])
    }
  end

  describe '#order' do
    specify{ expect(subject.order(field: 'hello')).to be_a(described_class) }
    specify{ expect(subject.order(field: 'hello')).not_to eq(subject) }
    specify{ expect{ subject.order(field: 'hello') }.not_to change{ subject.criteria.sort } }

    specify{ expect(subject.order(:field).criteria.sort).to eq([:field]) }
    specify{ expect(subject.order([:field1, :field2]).criteria.sort).to eq([:field1, :field2]) }
    specify{ expect(subject.order(field: :asc).criteria.sort).to eq([{ field: :asc }]) }
    specify{ expect(
      subject.order(field1: { order: :asc }, field2: :desc).order([:field3], :field4).criteria.sort
    ).to eq([{field1: {order: :asc}}, {field2: :desc}, :field3, :field4]) }
  end

  describe '#reorder' do
    specify{ expect(subject.reorder(field: 'hello')).to be_a(described_class) }
    specify{ expect(subject.reorder(field: 'hello')).not_to eq(subject) }
    specify{ expect{ subject.reorder(field: 'hello') }.not_to change{ subject.criteria.sort } }

    specify{ expect(subject.order(:field1).reorder(:field2).criteria.sort).to eq([:field2]) }
    specify{ expect(subject.order(:field1).reorder(:field2).order(:field3).criteria.sort).to eq([:field2, :field3]) }
    specify{ expect(subject.order(:field1).reorder(:field2).reorder(:field3).criteria.sort).to eq([:field3]) }
  end

  describe '#only' do
    specify{ expect(subject.only(:field)).to be_a described_class }
    specify{ expect(subject.only(:field)).not_to eq(subject) }
    specify{ expect{ subject.only(:field) }.not_to change{ subject.criteria.fields } }

    specify{ expect(subject.only(:field1, :field2).criteria.fields).to match_array(['field1', 'field2']) }
    specify{ expect(
      subject.only([:field1, :field2]).only(:field3).criteria.fields
    ).to match_array(['field1', 'field2', 'field3']) }
  end

  describe '#only!' do
    specify{ expect(subject.only!(:field)).to be_a(described_class) }
    specify{ expect(subject.only!(:field)).not_to eq(subject) }
    specify{ expect{ subject.only!(:field) }.not_to change{ subject.criteria.fields } }

    specify{ expect(subject.only!(:field1, :field2).criteria.fields).to match_array(['field1', 'field2']) }
    specify{ expect(subject.only!([:field1, :field2]).only!(:field3).criteria.fields).to eq(['field3']) }
    specify{ expect(subject.only([:field1, :field2]).only!(:field3).criteria.fields).to eq(['field3']) }
  end

  describe '#types' do
    specify{ expect(subject.types(:product)).to be_a(described_class) }
    specify{ expect(subject.types(:product)).not_to eq(subject) }
    specify{ expect{ subject.types(:product) }.not_to change{ subject.criteria.types } }

    specify{ expect(subject.types(:user).criteria.types).to eq(['user']) }
    specify{ expect(subject.types(:product, :city).criteria.types).to match_array(['product', 'city']) }
    specify{ expect(
      subject.types([:product, :city]).types(:country).criteria.types
    ).to match_array(['product', 'city', 'country']) }
  end

  describe '#types!' do
    specify{ expect(subject.types!(:product)).to be_a(described_class) }
    specify{ expect(subject.types!(:product)).not_to eq(subject) }
    specify{ expect{ subject.types!(:product) }.not_to change{ subject.criteria.types } }

    specify{ expect(subject.types!(:user).criteria.types).to eq(['user']) }
    specify{ expect(subject.types!(:product, :city).criteria.types).to match_array(['product', 'city']) }
    specify{ expect(subject.types!([:product, :city]).types!(:country).criteria.types).to eq(['country']) }
    specify{ expect(subject.types([:product, :city]).types!(:country).criteria.types).to eq(['country']) }
  end

  describe '#none' do
    specify{ expect(subject.none).to be_a(described_class) }
    specify{ expect(subject.none).not_to eq(subject) }
    specify{ expect(subject.none.criteria).to be_none }
  end

  describe '#merge' do
    let(:query){ ChewyQuery::Builder.new(:products) }

    specify{ expect(
      subject.filter{ name == 'name' }.merge(query.filter{ age == 42 }).criteria.filters
    ).to eq([{ term: { 'name' => 'name' } }, { term: { 'age' => 42 } }]) }
  end
end
