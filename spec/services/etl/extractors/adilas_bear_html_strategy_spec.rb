require 'rails_helper'

RSpec.describe ETL::Extractors::AdilasBearHTMLStrategy do
  subject { ETL::Extractors::AdilasBearHTMLStrategy.new(source_data, options) }
  let(:source_data) do
    VCR.use_cassette("adilas/#{url.split('?').last}") do
      open(url)
    end
  end
  let(:options) { {} }

  describe '#extract' do
    context 'when complete and valid HTML data is provided' do

      let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=314' }
      let(:attributes) { {full_name: 'Kaci Lickteig', bib_number: '1', gender: 'F', age: '30', city: 'Omaha', state_code: 'NE', times: times} }
      let(:times) { {0 => ['9/23/2016 6:00:00 am', '9/23/2016 7:45:30 am'],
                     1 => ['9/23/2016 7:45:31 am', '9/23/2016 9:23:00 am'],
                     2 => ['9/23/2016 9:23:00 am', '9/23/2016 9:50:19 am'],
                     3 => ['9/23/2016 9:50:19 am', '9/23/2016 11:13:57 am'],
                     4 => ['9/23/2016 11:15:11 am', '9/23/2016 12:25:42 pm'],
                     5 => ['9/23/2016 12:30:35 pm', '9/23/2016 1:56:10 pm'],
                     6 => ['9/23/2016 2:04:13 pm', '9/23/2016 3:38:03 pm'],
                     7 => ['9/23/2016 3:39:12 pm', '... ...'],
                     9 => ['9/23/2016 6:23:00 pm', '9/24/2016 8:20:00 pm'],
                     10 => ['9/24/2016 8:21:00 pm', '9/23/2016 10:12:57 pm'],
                     11 => ['9/23/2016 10:13:55 pm', '9/23/2016 10:45:18 pm'],
                     12 => ['9/23/2016 10:45:18 pm', '9/24/2016 1:13:49 am'],
                     13 => ['9/24/2016 1:15:38 am', '9/24/2016 2:27:57 am'],
                     8 => ['9/23/2016 6:20:00 pm', '9/23/2016 6:20:00 pm']} }

      it 'returns an OpenStruct containing effort and time information' do
        expect(subject.extract).to eq(OpenStruct.new(attributes))
      end
    end

    context 'when incomplete but valid HTML data is provided' do
      let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }
      let(:attributes) { {full_name: 'Linda McFadden', bib_number: '187', gender: 'F', age: '54', city: 'Modesto', state_code: 'CA', times: times} }
      let(:times) { {0 => ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am'],
                     1 => ['9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm'],
                     2 => ['9/23/2016 12:30:29 pm', '9/24/2016 1:49:11 pm'],
                     3 => ['9/23/2016 1:49:11 pm', '... ...']} }

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
