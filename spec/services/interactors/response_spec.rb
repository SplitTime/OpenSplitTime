RSpec.describe Interactors::Response do
  subject { Interactors::Response.new(errors, message, resources) }
  let(:message) { '' }
  let(:resources) { [] }

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

  describe '#message_with_error_report' do
    let(:message) { 'This thing broke' }
    let(:errors) { [{title: 'Bad error', detail: {message: 'Some bad stuff happened'}}] }

    it 'reports a message with the associated error report' do
      expect(subject.message_with_error_report).to eq("This thing broke: 1 error was reported:\nBad error: Some bad stuff happened")
    end
  end

  describe '#merge' do
    subject { Interactors::Response.new(errors_1, message_1, resources_1) }
    let(:errors_1) { [{title: 'Bad error', detail: {message: 'Some bad stuff happened'}}] }
    let(:message_1) { 'This thing broke' }
    let(:resources_1) { [SplitTime.new] }
    let(:response_2) { Interactors::Response.new(errors_2, message_2, resources_2) }
    let(:errors_2) { [{title: 'Worse error', detail: {message: 'Some really bad stuff happened'}}] }
    let(:message_2) { 'This thing broke in a different way' }
    let(:resources_2) { [Effort.new] }

    context 'when the other is a populated Interactors::Response object' do
      it 'combines errors, messages, and resources' do
        merged_response = subject.merge(response_2)
        expect(merged_response).to be_a(Interactors::Response)
        expect(merged_response.errors).to eq(errors_1 + errors_2)
        expect(merged_response.message).to eq([message_1, message_2].join("\n"))
        expect(merged_response.resources).to eq(resources_1 + resources_2)
      end
    end

    context 'when self has no resources component' do
      let(:resources_1) { nil }

      it 'combines errors, messages, and resources' do
        merged_response = subject.merge(response_2)
        expect(merged_response).to be_a(Interactors::Response)
        expect(merged_response.errors).to eq(errors_1 + errors_2)
        expect(merged_response.message).to eq([message_1, message_2].join("\n"))
        expect(merged_response.resources).to eq(resources_2)
      end
    end

    context 'when other has no resources component' do
      let(:resources_2) { nil }

      it 'combines errors, messages, and resources' do
        merged_response = subject.merge(response_2)
        expect(merged_response).to be_a(Interactors::Response)
        expect(merged_response.errors).to eq(errors_1 + errors_2)
        expect(merged_response.message).to eq([message_1, message_2].join("\n"))
        expect(merged_response.resources).to eq(resources_1)
      end
    end

    context 'when the other is nil' do
      let(:response_2) { nil }

      it 'returns self' do
        merged_response = subject.merge(response_2)
        expect(merged_response).to be_a(Interactors::Response)
        expect(merged_response.errors).to eq(errors_1)
        expect(merged_response.message).to eq(message_1)
        expect(merged_response.resources).to eq(resources_1)
      end
    end
  end
end
