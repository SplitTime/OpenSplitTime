require_relative '../../app/queries/base_query'

RSpec.describe BaseQuery do
  describe '.sql_order_from_hash' do
    subject { BaseQuery.sql_order_from_hash(sort_fields, allowed, default) }
    let(:default) { 'name asc' }
    let(:allowed) { %w(name age) }

    context 'when sort_fields hash is provided with symbols as keys' do
      let(:sort_fields) { {name: :asc, age: :desc} }

      it 'returns a string of fields in SQL format' do
        expect(subject).to eq('name asc, age desc')
      end
    end

    context 'when sort_fields hash is provided with strings as keys' do
      let(:sort_fields) { {'name' => :asc, 'age' => :desc} }
      let(:allowed) { %w(name age) }

      it 'returns a string of fields in SQL format' do
        expect(subject).to eq('name asc, age desc')
      end
    end

    context 'when sort_fields hash is provided with strings as keys and allowed is provided as an array of symbols' do
      let(:sort_fields) { {'name' => :asc, 'age' => :desc} }
      let(:allowed) { %i(name age) }

      it 'returns a string of fields in SQL format' do
        expect(subject).to eq('name asc, age desc')
      end
    end

    context 'when sort is nil' do
      let(:sort_fields) { nil }

      it 'returns the default string' do
        expect(subject).to eq('name asc')
      end
    end

    context 'when sort is an empty hash' do
      let(:sort_fields) { {} }

      it 'returns the default string' do
        expect(subject).to eq('name asc')
      end
    end
  end

  describe '.sql_select_from_string' do
    subject { BaseQuery.sql_select_from_string(column_names, allowed, default) }
    let(:allowed) { [:id, :first_name, :last_name] }
    let(:default) { '*' }

    context 'when column_names are all allowed' do
      let(:column_names) { 'id,first_name,last_name' }

      it 'returns the entire string' do
        expect(subject).to eq('id, first_name, last_name')
      end
    end

    context 'when some column_names are not allowed' do
      let(:column_names) { 'id,first_name,last_name,birthdate' }

      it 'returns the allowed names' do
        expect(subject).to eq('id, first_name, last_name')
      end
    end

    context 'when column_names are separated by spaces' do
      let(:column_names) { 'id, first_name, last_name' }

      it 'returns the entire string' do
        expect(subject).to eq('id, first_name, last_name')
      end
    end

    context 'when no column_names are allowed' do
      let(:column_names) { 'this,that' }

      it 'returns the default string' do
        expect(subject).to eq('*')
      end
    end

    context 'when column_names is an empty string' do
      let(:column_names) { '' }

      it 'returns the default string' do
        expect(subject).to eq('*')
      end
    end

    context 'when column_names is nil' do
      let(:column_names) { nil }

      it 'returns the default string' do
        expect(subject).to eq('*')
      end
    end
  end
end
