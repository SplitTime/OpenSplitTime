# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PreparedParams do
  subject { PreparedParams.new(params, permitted, permitted_query) }
  let(:permitted) { [] }
  let(:permitted_query) { [] }

  describe '#initialize' do
    let(:params) { ActionController::Parameters.new }

    it 'initializes given an instance of ActionControllers::Parameters' do
      expect { subject }.not_to raise_error
    end
  end

  describe '#data' do
    let(:params) { ActionController::Parameters.new(data: data_params) }
    let(:permitted) { [:name, :age] }

    context 'when provided with params[:data] in jsonapi format' do
      let(:data_params) { {id: 123, attributes: {name: 'John Doe', age: 50}} }

      it 'returns a hash containing the attributes' do
        expected = {'name' => 'John Doe', 'age' => 50}
        validate_param('data', expected)
      end

      it 'responds indifferently to string and symbol keys' do
        expect(subject[:data][:name]).to eq('John Doe')
        expect(subject[:data]['name']).to eq('John Doe')
      end
    end

    context 'when provided with non-permitted attributes' do
      let(:data_params) { {id: 123, attributes: {name: 'John Doe', age: 50, role: 'admin'}} }

      it 'returns a hash containing only the permitted attributes' do
        expected = {'name' => 'John Doe', 'age' => 50}
        validate_param('data', expected)
      end
    end

    context 'when data is an empty hash' do
      let(:data_params) { {} }

      it 'returns an empty hash' do
        expected = {}
        validate_param('data', expected)
      end
    end

    context 'when data is nil' do
      let(:data_params) { nil }

      it 'returns an empty hash' do
        expected = {}
        validate_param('data', expected)
      end
    end
  end

  describe '#editable' do
    let(:params) { ActionController::Parameters.new(filter: filter_params) }

    context 'when provided with a [:filter][:editable] key as true' do
      let(:filter_params) { {'editable' => 'true', 'state_code' => '', 'country_code' => 'US'} }

      it 'returns true' do
        expected = true
        validate_param('editable', expected)
      end
    end

    context 'when provided with a [:filter][:editable] key as false' do
      let(:filter_params) { {'editable' => 'false', 'state_code' => '', 'country_code' => 'US'} }

      it 'returns false' do
        expected = false
        validate_param('editable', expected)
      end
    end

    context 'when no [:filter][:editable] key is present' do
      let(:filter_params) { {'state_code' => '', 'country_code' => 'US'} }

      it 'returns nil' do
        expected = nil
        validate_param('editable', expected)
      end
    end

    context 'when no [:filter] key is present' do
      let(:filter_params) { nil }

      it 'returns nil' do
        expected = nil
        validate_param('editable', expected)
      end
    end
  end

  describe '#fields' do
    let(:params) { ActionController::Parameters.new(fields: field_params) }
    let(:permitted_query) { [:name, :age] }

    context 'when provided with fields for a single model in jsonapi format' do
      let(:field_params) { {'courses' => 'name,description'} }

      it 'returns a hash with the model name as the key and an array of fields as the value' do
        expected = {'courses' => [:name, :description]}
        validate_param('fields', expected)
      end

      it 'responds indifferently to string and symbol keys' do
        expect(subject[:fields][:courses]).to eq([:name, :description])
        expect(subject[:fields]['courses']).to eq([:name, :description])
      end
    end

    context 'when provided with camelCased field names in jsonapi format' do
      let(:field_params) { {'split_times' => 'subSplitBitkey,countryCode'} }

      it 'returns a hash with the model name as the key and an array of fields as the value' do
        expected = {'split_times' => [:subSplitBitkey, :countryCode]}
        validate_param('fields', expected)
      end
    end

    context 'when provided with underscored field names in jsonapi format' do
      let(:field_params) { {'split_times' => 'sub_split_bitkey,country_code'} }

      it 'returns a hash with the model name as the key and an array of fields as the value' do
        expected = {'split_times' => [:subSplitBitkey, :countryCode]}
        validate_param('fields', expected)
      end
    end

    context 'when provided with fields for multiple models in jsonapi format' do
      let(:field_params) { {'courses' => 'name,description',
                            'splits' => 'latitude,longitude,distance_from_start'} }

      it 'returns a hash with the model names as the keys and arrays of fields as the values' do
        expected = {'courses' => [:name, :description], 'splits' => [:latitude, :longitude, :distanceFromStart]}
        validate_param('fields', expected)
      end
    end

    context 'when provided with a single model and empty string in jsonapi format' do
      let(:field_params) { {'courses' => ''} }

      it 'returns a hash with the model name as the key and an empty array as the value' do
        expected = {'courses' => []}
        validate_param('fields', expected)
      end
    end

    context 'when provided with an empty hash' do
      let(:field_params) { {} }

      it 'returns an empty hash' do
        expected = {}
        validate_param('fields', expected)
      end
    end

    context 'when fields param is nil' do
      let(:field_params) { nil }

      it 'returns an empty hash' do
        expected = {}
        validate_param('fields', expected)
      end
    end
  end

  describe '#filter' do
    let(:params) { ActionController::Parameters.new(filter: filter_params) }
    let(:permitted_query) { [:state_code, :country_code] }

    context 'when provided with a single field and value' do
      let(:filter_params) { {'state_code' => 'NM'} }

      it 'returns the field and the value' do
        expected = {'state_code' => 'NM'}
        validate_param('filter', expected)
      end

      it 'responds indifferently to string and symbol keys' do
        expect(subject[:filter][:state_code]).to eq('NM')
        expect(subject[:filter]['state_code']).to eq('NM')
      end

      it 'works correctly when used as the argument in an ActiveRecord #where method' do
        relation = Effort.where(subject[:filter])
        expect(relation.to_sql).to include("WHERE \"efforts\".\"state_code\" = 'NM'")
      end
    end

    context 'when provided with a single field and a list of values' do
      let(:filter_params) { {'state_code' => 'NM,AZ,NY'} }

      it 'converts the list to an array' do
        expected = {'state_code' => %w(NM AZ NY)}
        validate_param('filter', expected)
      end
    end

    context 'when provided with a single field and an array of values' do
      let(:filter_params) { {'state_code' => %w(NM AZ NY)} }

      it 'preserves the array' do
        expected = {'state_code' => %w(NM AZ NY)}
        validate_param('filter', expected)
      end
    end

    context 'when provided with multiple fields and lists of values' do
      let(:filter_params) { {'state_code' => 'NM,AZ,BC', 'country_code' => 'US,CA'} }

      it 'converts the lists to arrays' do
        expected = {'state_code' => %w(NM AZ BC), 'country_code' => %w(US CA)}
        validate_param('filter', expected)
      end

      it 'works correctly when used as the argument in an ActiveRecord #where method' do
        relation = Effort.where(subject[:filter])
        expect(relation.to_sql)
            .to include("WHERE \"efforts\".\"state_code\" IN ('NM', 'AZ', 'BC') AND \"efforts\".\"country_code\" IN ('US', 'CA')")
      end
    end

    context 'when provided with multiple fields combined with "editable" and "search" keys' do
      let(:filter_params) { {'state_code' => 'NM,AZ,BC', 'country_code' => 'US,CA', 'search' => 'colorado', 'editable' => 'true'} }

      it 'ignores the "search" and "editable" keys' do
        expected = {'state_code' => %w(NM AZ BC), 'country_code' => %w(US CA)}
        validate_param('filter', expected)
      end
    end

    context 'when provided with a field having an empty string for its value' do
      let(:filter_params) { {'state_code' => '', 'country_code' => 'US'} }

      it 'returns the field with nil as its value' do
        expected = {'state_code' => nil, 'country_code' => 'US'}
        validate_param('filter', expected)
      end
    end

    context 'when provided with a field having nil as its value' do
      let(:filter_params) { {'state_code' => nil, 'country_code' => 'US'} }

      it 'returns the field with nil as its value' do
        expected = {'state_code' => nil, 'country_code' => 'US'}
        validate_param('filter', expected)
      end
    end

    context 'when no filter param exists' do
      let(:filter_params) { nil }

      it 'returns an empty hash' do
        expected = {}
        validate_param('filter', expected)
      end
    end
  end

  describe '#filter[:gender]' do
    let(:params) { ActionController::Parameters.new(filter: {gender: gender_param}) }
    let(:permitted_query) { [:gender] }
    let(:gender) { params.dig('filter', 'gender') }

    context 'when provided with "male"' do
      let(:gender_param) { 'male' }

      it 'returns an array containing [0]' do
        expected = {'gender' => [0]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with "female"' do
      let(:gender_param) { 'female' }

      it 'returns an array containing [1]' do
        expected = {'gender' => [1]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with the names of both genders' do
      let(:gender_param) { 'male,female' }

      it 'returns an array containing numeric values for both genders' do
        expected = {'gender' => [0, 1]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with combined' do
      let(:gender_param) { 'combined' }

      it 'returns an array containing numeric values for both genders' do
        expected = {'gender' => [0, 1]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with "0"' do
      let(:gender_param) { '0' }

      it 'returns an array containing [0]' do
        expected = {'gender' => [0]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with "1"' do
      let(:gender_param) { '1' }

      it 'returns an array containing [1]' do
        expected = {'gender' => [1]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with numbers representing both genders' do
      let(:gender_param) { %w(0 1) }

      it 'returns an array containing numeric values for both genders' do
        expected = {'gender' => [0, 1]}
        validate_param('filter', expected)
      end
    end

    context 'when provided with an empty array' do
      let(:gender_param) { [] }

      it 'returns an array containing numeric values for both genders' do
        expected = {'gender' => [0, 1]}
        validate_param('filter', expected)
      end
    end

    context 'when gender param is nil' do
      let(:gender_param) { nil }

      it 'returns an array containing numeric values for both genders' do
        expected = {'gender' => [0, 1]}
        validate_param('filter', expected)
      end
    end
  end

  describe '#include' do
    let(:params) { ActionController::Parameters.new(include: include_params) }

    context 'when provided with camelCased models and relations in jsonapi format' do
      let(:include_params) { 'course,split.splitTimes' }

      it 'returns an array with camelCase converted to underscore' do
        expected = ["course", "split.split_times"]
        validate_param('include', expected)
      end
    end

    context 'when provided with an empty string' do
      let(:include_params) { '' }

      it 'returns an empty array' do
        expected = []
        validate_param('include', expected)
      end
    end

    context 'when include param is nil' do
      let(:include_params) { nil }

      it 'returns an empty array' do
        expected = []
        validate_param('include', expected)
      end
    end
  end

  describe '#original_params' do
    let(:params) { ActionController::Parameters.new(filter: {search: 'john', state_code: 'CO'}, include: 'efforts', sort: 'last_name') }

    it 'returns the provided params' do
      expected = params
      validate_param('original_params', expected)
    end
  end

  describe '#search' do
    let(:params) { ActionController::Parameters.new(filter: {search: search_param}) }

    context 'when search param contains a string' do
      let(:search_param) { 'john doe co' }

      it 'returns the string' do
        expected = 'john doe co'
        validate_param('search', expected)
      end
    end

    context 'when search param contains an empty string' do
      let(:search_param) { '' }

      it 'returns nil' do
        expected = nil
        validate_param('search', expected)
      end
    end

    context 'when search param is nil' do
      let(:search_param) { nil }

      it 'returns nil' do
        expected = nil
        validate_param('search', expected)
      end
    end

    context 'when filter param is nil' do
      let(:params) { ActionController::Parameters.new(filter: nil) }

      it 'returns nil' do
        expected = nil
        validate_param('search', expected)
      end
    end
  end

  describe '#sort' do
    let(:params) { ActionController::Parameters.new(sort: sort_string) }
    let(:permitted_query) { [:last_name, :age, :country_code] }

    context 'when provided with params[:sort] in jsonapi format' do
      let(:sort_string) { 'last_name,-age' }
      let(:event) { events(:sum_55k) }

      it 'returns a hash containing the given data' do
        expected = {'last_name' => :asc, 'age' => :desc}
        validate_param('sort', expected)
      end

      it 'responds indifferently to string and symbol keys' do
        expect(subject[:sort][:last_name]).to eq(:asc)
        expect(subject[:sort]['last_name']).to eq(:asc)
      end

      it 'works correctly when used as the argument in an ActiveRecord #order method' do
        event_efforts = event.efforts.order(subject[:sort])
        expect(event_efforts.first).to eq(efforts(:sum_55k_drop_bandera))

        sql = event_efforts.to_sql
        expect(sql).to include("\"last_name\" ASC")
        expect(sql).to include("\"age\" DESC")
      end
    end

    context 'when provided with params[:sort] fields in camelCase' do
      let(:sort_string) { 'lastName,-countryCode' }

      it 'returns a hash containing the given data' do
        expected = {'last_name' => :asc, 'country_code' => :desc}
        validate_param('sort', expected)
      end
    end

    context 'when provided with a non-permitted sort attribute' do
      let(:sort_string) { 'last_name,-age,role' }

      it 'returns a hash containing only the permitted attributes' do
        expected = {'last_name' => :asc, 'age' => :desc}
        validate_param('sort', expected)
      end
    end

    context 'when sort is an empty string' do
      let(:sort_string) { '' }

      it 'returns an empty hash' do
        expected = {}
        validate_param('sort', expected)
      end
    end

    context 'when sort is nil' do
      let(:sort_string) { nil }

      it 'returns an empty hash' do
        expected = {}
        validate_param('sort', expected)
      end
    end
  end

  def validate_param(method, expected)
    expect(subject.send(method)).to eq(expected)
    expect(subject[method.to_s]).to eq(expected)
    expect(subject[method.to_sym]).to eq(expected)
  end
end
