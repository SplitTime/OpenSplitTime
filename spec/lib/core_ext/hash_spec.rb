# frozen_string_literal: true

require_relative '../../../lib/core_ext/hash'

RSpec.describe Hash do
  describe '#camelize_keys' do
    it 'changes hash keys from symbolized underscore to symbolized camelCase format' do
      hash = {first_name: 'Johnny', last_name: 'Appleseed', age: 21}
      camelized = hash.camelize_keys
      expect(camelized).to eq({firstName: 'Johnny', lastName: 'Appleseed', age: 21})
    end

    it 'functions if hash keys are strings' do
      hash = {'first_name' => 'Johnny', 'last_name' => 'Appleseed', 'age' => 21}
      camelized = hash.camelize_keys
      expect(camelized).to eq({firstName: 'Johnny', lastName: 'Appleseed', age: 21})
    end

    it 'functions on nested hash keys' do
      hash = {first_name: 'Johnny', last_name: 'Appleseed', favorites: {comfort_pet: 'Cat', hair_color: 'Brown'}}
      camelized = hash.camelize_keys
      expect(camelized).to eq({firstName: 'Johnny', lastName: 'Appleseed', favorites: {comfortPet: 'Cat', hairColor: 'Brown'}})
    end
  end

  describe '#underscore_keys' do
    it 'changes hash keys from symbolized camelCase to symbolized underscore format' do
      hash = {firstName: 'Johnny', lastName: 'Appleseed', age: 21}
      underscored = hash.underscore_keys
      expect(underscored).to eq({first_name: 'Johnny', last_name: 'Appleseed', age: 21})
    end

    it 'functions if hash keys are strings' do
      hash = {'firstName' => 'Johnny', 'lastName' => 'Appleseed', 'age' => 21}
      underscored = hash.underscore_keys
      expect(underscored).to eq({first_name: 'Johnny', last_name: 'Appleseed', age: 21})
    end

    it 'functions on nested hash keys' do
      hash = {firstName: 'Johnny', lastName: 'Appleseed', favorites: {comfortPet: 'Cat', hairColor: 'Brown'}}
      underscored = hash.underscore_keys
      expect(underscored).to eq({first_name: 'Johnny', last_name: 'Appleseed', favorites: {comfort_pet: 'Cat', hair_color: 'Brown'}})
    end
  end
end
