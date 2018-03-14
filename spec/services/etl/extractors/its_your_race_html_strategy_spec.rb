require 'rails_helper'

RSpec.describe ETL::Extractors::ItsYourRaceHTMLStrategy do
  subject { ETL::Extractors::ItsYourRaceHTMLStrategy.new(source_data, options) }
  let(:source_data) do
    VCR.use_cassette("itsyourrace/#{url.split('/').last}") do
      open(url)
    end
  end
  let(:options) { {} }

  describe '#extract' do
    context 'when complete and valid HTML data is provided' do
      let(:url) { 'https://bhtr.itsyourrace.com//Results/384/2014/5798/100' }
      let(:attributes) { {full_name: 'William Abel', gender: 'male', age: '41', city: 'Byron', state_code: 'IL', times: times} }
      let(:times) do
        {'DF In' => '3:27:40.00', 'DF Out' => '05:24.00', 'FB In' => '7:18:29.00', 'FB Out' => '05:01.00',
         'Jaws In' => '13:02:36.00', 'Jaws Out' => '16:18.00', 'FBR In' => '18:38:18.00', 'FBR Out' => '11:47.00',
         'DFR In' => '23:35:34.00', 'DFR Out' => '11:24.00', 'Finish' => '27:44:15.52'}
      end

      it 'returns an OpenStruct containing effort and time information' do
        expect(subject.extract).to eq(OpenStruct.new(attributes))
      end
    end

    context 'when valid but incomplete HTML data is provided' do
      let(:url) { 'https://bhtr.itsyourrace.com//Results/384/2014/5798/108' }
      let(:attributes) { {full_name: 'Quintin Barney', gender: 'male', age: '54', city: 'Holladay', state_code: 'UT', times: times} }
      let(:times) do
        {'DF In' => '3:24:40.00', 'DF Out' => '02:31.00', 'FB In' => '7:50:16.00', 'FB Out' => '--',
         'Jaws In' => '15:31:49.00', 'Jaws Out' => '26:08.00', 'FBR In' => '22:43:34.00', 'FBR Out' => '11:12.00',
         'DFR In' => '--', 'DFR Out' => '--', 'Finish' => '--'}
      end

      it 'returns an OpenStruct containing effort and time information' do
        expect(subject.extract).to eq(OpenStruct.new(attributes))
      end
    end

    context 'when valid HTML data is provided with no times' do
      let(:url) { 'https://bhtr.itsyourrace.com//Results/384/2014/5798/104' }
      let(:attributes) { {full_name: 'Andreas Aguirre', gender: 'male', age: '35', city: 'San Diego', state_code: 'CA', times: times} }
      let(:times) do
        {'DF In' => '--', 'DF Out' => '--', 'FB In' => '--', 'FB Out' => '--',
         'Jaws In' => '--', 'Jaws Out' => '--', 'FBR In' => '--', 'FBR Out' => '--',
         'DFR In' => '--', 'DFR Out' => '--', 'Finish' => '--'}
      end

      it 'returns an OpenStruct containing effort and time information' do
        expect(subject.extract).to eq(OpenStruct.new(attributes))
      end
    end

    context 'when invalid HTML data is provided' do
      let(:url) { 'https://www.example.com' }

      it 'returns nil and provides a descriptive error message' do
        expect(subject.extract).to be_nil
        expect(subject.errors.first[:title]).to eq('Table is missing')
      end
    end
  end
end
