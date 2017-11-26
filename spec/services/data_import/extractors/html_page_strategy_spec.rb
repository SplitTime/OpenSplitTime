RSpec.describe DataImport::Extractors::HTMLPageStrategy do
  subject { DataImport::Extractors::HTMLPageStrategy.new(url, options) }
  let(:options) { {} }

  describe '#extract' do
    context 'when a valid URL is provided' do
      let(:url) { "https://www.example.com" }

      it 'returns raw data as a StringIO in html format' do
        html = subject.extract
        expect(html).to be_a(Nokogiri::HTML::Document)
        expect(html.xpath('/html/body/div/h1').text).to eq('Example Domain')
      end
    end

    context 'when a URL is provided with a valid domain name and a path that does not exist' do
      let(:url) { "https://www.example.com/pagethatdoesnotexist" }

      it 'returns nil and provides a descriptive error' do
        html = subject.extract
        expect(html).to be_nil
        expect(subject.errors.first[:title]).to match(/Bad URL/)
        expect(subject.errors.first[:detail][:messages].first).to eq("https://www.example.com/pagethatdoesnotexist reported an error: 404 Not Found")
      end
    end

    context 'when a URL is provided with a domain name that does not exist' do
      let(:url) { "https://www.websitethatdoesnotexist.com" }

      it 'returns nil' do
        html = subject.extract
        expect(html).to be_nil
        expect(subject.errors.first[:title]).to match(/Bad URL/)
        expect(subject.errors.first[:detail][:messages].first).to eq("https://www.websitethatdoesnotexist.com reported an error: Failed to open TCP connection to www.websitethatdoesnotexist.com:443 (getaddrinfo: nodename nor servname provided, or not known)")
      end
    end
  end
end
