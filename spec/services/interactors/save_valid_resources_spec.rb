require 'rails_helper'

RSpec.describe Interactors::SaveValidResources do
  let(:output_response) { Interactors::SaveValidResources.perform(input_response) }
  let(:input_response) { Interactors::Response.new(errors, message, resources) }
  let(:errors) { [] }
  let(:message) { '' }
  let(:resources) { {valid: valid_resources, invalid: invalid_resources} }

  describe '.perform' do
    context 'when resources exist under [:valid] and [:invalid] keys' do
      let(:valid_resources) { [build(:course), build(:person)] }
      let(:invalid_resources) { [build(:course, name: nil), build(:person, first_name: nil)] }

      it 'ignores resources under [:invalid] and saves resources under [:valid] to the database' do
        output_response
        expect(Course.count).to eq(1)
        expect(Person.count).to eq(1)
        expect(Course.first).to eq(valid_resources.first)
        expect(Person.first).to eq(valid_resources.second)
      end

      it 'returns a successful response containing the saved resources' do
        expect(output_response).to be_successful
        expect(output_response.resources[:saved]).to include(valid_resources.first)
        expect(output_response.resources[:saved]).to include(valid_resources.second)
      end
    end

    context 'when resources under the [:valid] key do not save' do
      let(:valid_resources) { [build(:course, name: nil), build(:person)] }
      let(:invalid_resources) { [] }

      it 'returns an unsuccessful response containing both saved and unsaved resources and descriptive errors' do
        expect(output_response).not_to be_successful
        expect(output_response.resources[:unsaved]).to include(valid_resources.first)
        expect(output_response.resources[:saved]).to include(valid_resources.second)
        expect(output_response.errors.first[:title]).to eq('Course could not be saved')
      end
    end
  end
end
