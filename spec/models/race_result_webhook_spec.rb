# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RaceResultWebhook, type: :model do
  describe 'associations' do
    it { should belong_to(:event).optional }
    it { should belong_to(:effort).optional }
    it { should belong_to(:split_time).optional }
  end
  
  describe 'validations' do
    subject { build(:race_result_webhook) }
    
    it { should validate_presence_of(:event_id) }
    it { should validate_presence_of(:webhook_id) }
    it { should validate_presence_of(:trigger_type) }
    it { should validate_presence_of(:webhook_timestamp) }
    it { should validate_presence_of(:payload) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[received processing processed failed]) }
  end
  
  describe 'scopes' do
    let!(:received_webhook) { create(:race_result_webhook, status: 'received') }
    let!(:processing_webhook) { create(:race_result_webhook, status: 'processing') }
    let!(:processed_webhook) { create(:race_result_webhook, status: 'processed') }
    let!(:failed_webhook) { create(:race_result_webhook, status: 'failed') }
    
    describe '.received' do
      it 'returns only received webhooks' do
        expect(described_class.received).to contain_exactly(received_webhook)
      end
    end
    
    describe '.processing' do
      it 'returns only processing webhooks' do
        expect(described_class.processing).to contain_exactly(processing_webhook)
      end
    end
    
    describe '.processed' do
      it 'returns only processed webhooks' do
        expect(described_class.processed).to contain_exactly(processed_webhook)
      end
    end
    
    describe '.failed' do
      it 'returns only failed webhooks' do
        expect(described_class.failed).to contain_exactly(failed_webhook)
      end
    end
    
    describe '.unprocessed' do
      it 'returns only received (unprocessed) webhooks' do
        expect(described_class.unprocessed).to contain_exactly(received_webhook)
      end
    end
    
    describe '.by_event' do
      let!(:event_webhook) { create(:race_result_webhook, event_id: 'event_123') }
      
      it 'filters webhooks by event_id' do
        expect(described_class.by_event('event_123')).to contain_exactly(event_webhook)
      end
    end
    
    describe '.by_trigger' do
      let!(:participant_webhook) { create(:race_result_webhook, trigger_type: 'new_participant') }
      
      it 'filters webhooks by trigger type' do
        expect(described_class.by_trigger('new_participant')).to contain_exactly(participant_webhook)
      end
    end
  end
  
  describe '.log_webhook' do
    let(:valid_params) do
      {
        event_id: '12345',
        webhook_id: 'wp_abc123',
        trigger: 'new_participant',
        timestamp: '2025-11-09T10:30:00Z',
        participant: {
          bib_number: '101',
          first_name: 'John',
          last_name: 'Doe'
        },
        source_ip: '192.168.1.1',
        user_agent: 'RaceResult/1.0'
      }
    end
    
    it 'creates a new webhook record' do
      expect {
        described_class.log_webhook(valid_params)
      }.to change(described_class, :count).by(1)
    end
    
    it 'stores all webhook data correctly' do
      webhook = described_class.log_webhook(valid_params)
      
      expect(webhook.event_id).to eq('12345')
      expect(webhook.webhook_id).to eq('wp_abc123')
      expect(webhook.trigger_type).to eq('new_participant')
      expect(webhook.source_ip).to eq('192.168.1.1')
      expect(webhook.status).to eq('received')
    end
    
    it 'handles missing trigger field' do
      params = valid_params.dup
      params.delete(:trigger)
      
      webhook = described_class.log_webhook(params)
      expect(webhook.trigger_type).to eq('unknown')
    end
    
    context 'when logging fails' do
      it 'returns nil and logs error' do
        allow(Rails.logger).to receive(:error)
        
        result = described_class.log_webhook({})
        
        expect(result).to be_nil
        expect(Rails.logger).to have_received(:error).at_least(:once)
      end
    end
  end
  
  describe '#mark_as_processing!' do
    let(:webhook) { create(:race_result_webhook, status: 'received') }
    
    it 'updates status to processing' do
      webhook.mark_as_processing!
      expect(webhook.status).to eq('processing')
    end
    
    it 'sets processed_at timestamp' do
      webhook.mark_as_processing!
      expect(webhook.processed_at).to be_present
    end
  end
  
  describe '#mark_as_processed!' do
    let(:webhook) { create(:race_result_webhook, status: 'processing') }
    
    it 'updates status to processed' do
      webhook.mark_as_processed!
      expect(webhook.status).to eq('processed')
    end
    
    it 'sets processed_at timestamp' do
      webhook.mark_as_processed!
      expect(webhook.processed_at).to be_present
    end
  end
  
  describe '#mark_as_failed!' do
    let(:webhook) { create(:race_result_webhook, status: 'processing') }
    let(:error) { StandardError.new('Test error') }
    
    it 'updates status to failed' do
      webhook.mark_as_failed!(error)
      expect(webhook.status).to eq('failed')
    end
    
    it 'stores error message' do
      webhook.mark_as_failed!(error)
      expect(webhook.error_message).to eq('Test error')
    end
    
    it 'sets processed_at timestamp' do
      webhook.mark_as_failed!(error)
      expect(webhook.processed_at).to be_present
    end
  end
  
  describe '#participant_data' do
    let(:webhook) do
      create(:race_result_webhook, 
             payload: { 'participant' => { 'bib_number' => '101' } })
    end
    
    it 'returns participant data from payload' do
      expect(webhook.participant_data).to eq({ 'bib_number' => '101' })
    end
  end
  
  describe '#raw_data' do
    let(:webhook) do
      create(:race_result_webhook,
             payload: { 'raw_data' => { 'split_name' => 'Mile 10' } })
    end
    
    it 'returns raw data from payload' do
      expect(webhook.raw_data).to eq({ 'split_name' => 'Mile 10' })
    end
  end
  
  describe '#bib_number' do
    context 'from participant data' do
      let(:webhook) do
        create(:race_result_webhook,
               payload: { 'participant' => { 'bib_number' => '101' } })
      end
      
      it 'returns bib number from participant' do
        expect(webhook.bib_number).to eq('101')
      end
    end
    
    context 'from raw data' do
      let(:webhook) do
        create(:race_result_webhook,
               payload: { 'raw_data' => { 'bib_number' => '202' } })
      end
      
      it 'returns bib number from raw data' do
        expect(webhook.bib_number).to eq('202')
      end
    end
  end
  
  describe 'trigger type predicates' do
    describe '#new_participant?' do
      it 'returns true for new_participant trigger' do
        webhook = create(:race_result_webhook, trigger_type: 'new_participant')
        expect(webhook).to be_new_participant
      end
      
      it 'returns false for other triggers' do
        webhook = create(:race_result_webhook, trigger_type: 'new_raw_data')
        expect(webhook).not_to be_new_participant
      end
    end
    
    describe '#new_raw_data?' do
      it 'returns true for new_raw_data trigger' do
        webhook = create(:race_result_webhook, trigger_type: 'new_raw_data')
        expect(webhook).to be_new_raw_data
      end
    end
  end
  
  describe '#to_s' do
    let(:webhook) { create(:race_result_webhook) }
    
    it 'returns a descriptive string' do
      expect(webhook.to_s).to include('RaceResult Webhook')
      expect(webhook.to_s).to include(webhook.trigger_type)
      expect(webhook.to_s).to include(webhook.event_id)
    end
  end
end

# Factory for testing
FactoryBot.define do
  factory :race_result_webhook do
    sequence(:event_id) { |n| "event_#{n}" }
    sequence(:webhook_id) { |n| "webhook_#{n}" }
    trigger_type { 'new_participant' }
    webhook_timestamp { Time.current }
    payload do
      {
        event_id: event_id,
        webhook_id: webhook_id,
        timestamp: webhook_timestamp.iso8601,
        participant: {
          bib_number: '101',
          first_name: 'Test',
          last_name: 'Runner'
        }
      }
    end
    status { 'received' }
    source_ip { '192.168.1.1' }
    user_agent { 'RaceResult/1.0' }
  end
end