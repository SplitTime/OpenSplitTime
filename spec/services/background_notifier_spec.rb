require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe BackgroundNotifier do
  let(:channel) { 'progress_1' }
  let(:event) { 'update' }
  let(:message_data) { {message: 'Progressing', current_object: 0, total_objects: 100} }

  describe '#initialization' do
    it 'initializes when provided with a channel, an event, and a message_data hash' do
      expect { BackgroundNotifier.new(channel: channel, event: event, body: message_data) }
          .not_to raise_error
    end

    it 'raises an error if no channel is provided' do
      expect { BackgroundNotifier.new(channel: nil, event: event) }
          .to raise_error(/must include channel/)
    end

    it 'raises an error if no event is provided' do
      expect { BackgroundNotifier.new(channel: channel, event: nil) }
          .to raise_error(/must include event/)
    end
  end

  describe '#publish' do
    context 'when provided with message data' do
      let(:args) { {channel: channel, event: event, message: 'Progressing'} }

      it 'sends a message to Pusher' do
        notifier = BackgroundNotifier.new(args)
        expected = {message: 'Progressing'}
        expect(Pusher).to receive(:trigger).with(channel, event, expected)
        notifier.publish
      end
    end

    context 'when provided without a message but with action, resource, current_object, and total_objects' do
      let(:args) { {channel: channel, event: event, action: 'imported', resource: 'effort', current_object: 10, total_objects: 50} }

      it 'creates a message and a progress percentage' do
        notifier = BackgroundNotifier.new(args)
        expected = {message: 'Imported 10 of 50 efforts', current_object: 10, total_objects: 50,
                    progress: 20, action: 'imported', resource: 'effort'}
        expect(Pusher).to receive(:trigger).with(channel, event, expected)
        notifier.publish
      end
    end

    context 'when provided with a channel and event but no message_data' do
      let(:message_data) { {} }

      it 'sends a message to Pusher with an empty hash for the message argument' do
        notifier = BackgroundNotifier.new(channel: channel, event: event, body: message_data)
        expected = {}
        expect(Pusher).to receive(:trigger).with(channel, event, expected)
        notifier.publish
      end
    end
  end
end
