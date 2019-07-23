# frozen_string_literal: true

RSpec.shared_examples_for 'subscribable' do
  let(:model) { described_class }
  let(:model_name) { model.name.underscore.to_sym }

  describe 'assign_topic_resource' do
    let(:subject) { build(model_name) }

    context 'when generate_new_topic_resource? returns true' do
      before { allow(subject).to receive(:generate_new_topic_resource?).and_return(true) }

      it 'sets the topic_resource_key' do
        expect(subject.topic_resource_key).to be_nil
        subject.assign_topic_resource
        expect(subject.topic_resource_key).not_to be_nil
      end

      it 'sends a :generate message to the topic_manager' do
        expect(subject.topic_manager).to receive(:generate).with(resource: subject)
        subject.assign_topic_resource
      end
    end

    context 'when generate_new_topic_resource? returns false' do
      before { allow(subject).to receive(:generate_new_topic_resource?).and_return(false) }

      it 'sets the topic_resource_key' do
        expect(subject.topic_resource_key).to be_nil
        subject.assign_topic_resource
        expect(subject.topic_resource_key).to be_nil
      end

      it 'does not send a :generate message to the topic_manager' do
        expect(subject.topic_manager).not_to receive(:generate)
        subject.assign_topic_resource
      end
    end
  end

  describe 'unassign_topic_resource' do
    let(:subject) { build(model_name) }
    let(:topic_resource_key) { '123' }

    context 'when topic_resource_key exists' do
      before { subject.update(topic_resource_key: topic_resource_key) }

      it 'removes the topic_resource_key' do
        expect(subject.topic_resource_key).to eq(topic_resource_key)
        subject.unassign_topic_resource
        expect(subject.topic_resource_key).to be_nil
      end

      it 'sends a :delete message to the topic_manager' do
        expect(subject.topic_manager).to receive(:delete).with(resource: subject)
        subject.unassign_topic_resource
      end
    end
  end
end
