RSpec.describe ETL::Extractors::AdilasBearHTMLStrategy do
  subject { ETL::Extractors::AdilasBearHTMLStrategy.new(url, options) }
  let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }
  let(:options) { {} }
  let(:attributes) { {full_name: 'Linda McFadden', bib_number: '187', gender: 'F', age: '54', city: 'Modesto', state_code: 'CA', times: times} }
  let(:times) { ['9/23/2016 6:00:00 am', '9/23/2016 8:49:10 am',
                 '9/23/2016 8:49:10 am', '9/23/2016 12:30:27 pm',
                 '9/23/2016 12:30:29 pm', '9/24/2016 1:49:11 pm',
                 '9/23/2016 1:49:11 pm', '... ...'] }

  describe '#extract' do
    context 'when a valid URL is provided' do
      let(:url) { 'https://www.adilas.biz/bear100/runner_details.cfm?id=500' }

      it 'returns an OpenStruct containing effort and time information' do
        expect(subject.extract).to eq(OpenStruct.new(attributes))
      end
    end

    context 'when a URL is provided with a valid domain name and a path that does not exist' do
      let(:url) { 'https://www.example.com/pagethatdoesnotexist' }

      it 'returns nil and provides a descriptive error' do
        html = subject.extract
        expect(html).to be_nil
        expect(subject.errors.first[:title]).to match(/Bad URL/)
        expect(subject.errors.first[:detail][:messages].first).to include('https://www.example.com/pagethatdoesnotexist reported an error')
        expect(subject.errors.first[:detail][:messages].first).to include('404')
      end
    end

    context 'when a URL is provided with a domain name that does not exist' do
      let(:url) { 'https://www.websitethatdoesnotexist.com' }

      it 'returns nil' do
        html = subject.extract
        expect(html).to be_nil
        expect(subject.errors.first[:title]).to match(/Bad URL/)
        expect(subject.errors.first[:detail][:messages].first).to include('https://www.websitethatdoesnotexist.com reported an error')
        expect(subject.errors.first[:detail][:messages].first).to include('443')
      end
    end
  end
end
