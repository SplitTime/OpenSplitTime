require 'rails_helper'

RSpec.describe EffortSchema, type: :model do

  describe 'to_a' do

    it 'should return an empty array when passed an empty array' do
      expect(EffortSchema.new([]).to_a).to eq([])
    end

    it 'should correctly match first and last name attributes' do
      header_column_titles = ['First Name', 'Last Name']
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:first_name, :last_name])
    end

    it 'should correctly match city, state, and country attributes' do
      header_column_titles = %w(State Country City)
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:state_code, :country_code, :city])
    end

    it 'should correctly match bib and wave attributes' do
      header_column_titles = ['Bib Number', 'Wave']
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:bib_number, :wave])
    end

    it 'should correctly match bib and wave attributes' do
      header_column_titles = ['Bib Number', 'Wave']
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:bib_number, :wave])
    end

    it 'should correctly match age, birthdate, and gender attributes' do
      header_column_titles = %w(Age Birthdate Gender)
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:age, :birthdate, :gender])
    end

    it 'should correctly match a full set of typical column titles' do
      header_column_titles = %w(Last First Sex Age Birthdate Bib State Country City)
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:last_name, :first_name, :gender, :age, :birthdate,
                                 :bib_number, :state_code, :country_code, :city])
    end

    it 'should ignore capitalization' do
      header_column_titles = %w(LAST_NAME first_name gEnDeR age BirthDate bib State Country CItY)
      schema = EffortSchema.new(header_column_titles)
      expect(schema.to_a).to eq([:last_name, :first_name, :gender, :age, :birthdate,
                                 :bib_number, :state_code, :country_code, :city])
    end

  end

end