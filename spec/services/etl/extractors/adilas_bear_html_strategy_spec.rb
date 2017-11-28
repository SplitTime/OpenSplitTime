RSpec.describe ETL::Extractors::AdilasBearHTMLStrategy do
  subject { ETL::Extractors::AdilasBearHTMLStrategy.new(source_data, options) }
  let(:source_data) { open(url) }
  let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }
  let(:options) { {} }
  let(:attributes) { {full_name: 'Linda McFadden', bib_number: '187', gender: 'F', age: '54', city: 'Modesto', state_code: 'CA', times: times} }
  let(:times) { ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am',
                 '9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm',
                 '9/23/2016 12:30:29 pm', '9/24/2016 1:49:11 pm',
                 '9/23/2016 1:49:11 pm', '... ...'] }

  describe '#extract' do
    context 'when valid HTML data is provided' do
      let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }

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
