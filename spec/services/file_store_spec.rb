require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe FileStore do
  describe '.read' do
    subject { FileStore.get(path_or_url) }

    context 'when path_or_url is a local file path pointing to an existing file' do
      let(:path_or_url) { '/spec/fixtures/files/test_efforts.csv' }

      it 'sends :new to File with the given path_or_url appended to the root directory' do
        expect(File).to receive(:new).with("#{Rails.root}#{path_or_url}")
        subject
      end

      it 'returns a File object' do
        expect(subject).to be_a(File)
        expect(subject.read).to start_with('first_name')
      end
    end

    context 'when path_or_url is a local file path that points to a nonexistent file' do
      let(:path_or_url) { '/non/existing/file' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when path_or_url is a public URL' do
      let(:path_or_url) { 'https://s3-us-west-2.amazonaws.com/opensplittime-development/test/test_efforts.csv' }

      it 'sends :open to OpenURI with the public URL' do
        expect(OpenURI).to receive(:open_uri).with(URI.parse(path_or_url))
        subject
      end

      it 'returns a StringIO object' do
        expect(subject).to be_a(StringIO)
        expect(subject.read).to start_with('first_name')
      end
    end

    context 'when path_or_url is a public URL and the file does not exist' do
      let(:path_or_url) { 'https://s3-us-west-2.amazonaws.com/opensplittime-development/test/non/existing/file' }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when path_or_url is an S3 key that exists' do
      let(:path_or_url) { 'test/test_rr_response.json' }

      it 'sends :read to S3FileManager with the key' do
        expect(S3FileManager).to receive(:read).with(path_or_url)
        subject
      end

      it 'returns a StringIO object' do
        expect(subject).to be_a(StringIO)
        expect(subject.read).to eq('') # AWS testing is stubbed
      end
    end

    context 'when path_or_url is an S3 key that does not exist' do
      let(:path_or_url) { 'test/test_efforts.csvx' }

      it 'returns nil' do
        skip # This test will fail so long as Aws::S3 returns stubbed objects in the test environment
        expect(subject).to be_nil
      end
    end
  end
end
