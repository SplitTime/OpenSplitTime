RSpec.describe Interactors::Response do
  subject { Interactors::Response.new(errors, message) }
  let(:message) { '' }

  describe '#successful?' do
    context 'when errors are present' do
      let(:errors) { [{title: 'Bad error', detail: {message: 'Some bad stuff happened'}}] }

      it 'returns true' do
        expect(subject.successful?).to eq(false)
      end
    end

    context 'when errors are not present' do
      let(:errors) { [] }

      it 'returns true' do
        expect(subject.successful?).to eq(true)
      end
    end
  end

  describe '#error_report' do
    context 'when no errors are present' do
      let(:errors) { [] }

      it 'returns a message to that effect' do
        expect(subject.error_report).to eq('No errors were reported')
      end
    end

    context 'when one error is present' do
      let(:errors) { [{title: 'Bad error', detail: {message: 'Some bad stuff happened'}}] }

      it 'indicates the number of errors and gives a detailed report' do
        expect(subject.error_report).to eq("1 error was reported:\nBad error: Some bad stuff happened")
      end
    end

    context 'when one error is present with multiple messages' do
      let(:errors) { [{title: 'Resource error', detail: {messages: ['Name is too long. ', 'Email is too short. ']}}] }

      it 'indicates the number of errors and gives a detailed report' do
        expect(subject.error_report).to eq("1 error was reported:\nResource error: Name is too long. Email is too short. ")
      end
    end

    context 'when more than one error is present' do
      let(:errors) { [{title: 'Bad error', detail: {message: 'Some bad stuff happened'}},
                      {title: 'Little error', detail: {message: 'Some other stuff happened'}}] }

      it 'indicates the number of errors and gives a detailed report' do
        expect(subject.error_report).to eq("2 errors were reported:\nBad error: Some bad stuff happened\nLittle error: Some other stuff happened")
      end
    end
  end
end
