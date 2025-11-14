# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::RaceResultWebhooks', type: :request do
  describe 'POST /api/v1/race_result_webhooks' do
    let(:webhook_url) { '/api/v1/race_result_webhooks' }
    let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }
    
    context 'with valid new participant webhook' do
      let(:valid_payload) do
        {
          event_id: '12345',
          webhook_id: 'wp_abc123',
          timestamp: '2025-11-09T10:30:00Z',
          trigger: 'new_participant',
          participant: {
            bib_number: '101',
            first_name: 'John',
            last_name: 'Doe',
            email: 'john.doe@example.com',
            gender: 'M',
            age: 35,
            city: 'Denver',
            state: 'CO',
            country: 'USA'
          }
        }
      end
      
      it 'creates a webhook record' do
        expect {
          post webhook_url, params: valid_payload.to_json, headers: headers
        }.to change(RaceResultWebhook, :count).by(1)
      end
      
      it 'returns success response' do
        post webhook_url, params: valid_payload.to_json, headers: headers
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Webhook received successfully')
        expect(json_response['webhook_id']).to be_present
      end
      
      it 'stores the complete payload' do
        post webhook_url, params: valid_payload.to_json, headers: headers
        
        webhook = RaceResultWebhook.last
        expect(webhook.event_id).to eq('12345')
        expect(webhook.webhook_id).to eq('wp_abc123')
        expect(webhook.trigger_type).to eq('new_participant')
        expect(webhook.payload['participant']['bib_number']).to eq('101')
      end
      
      it 'stores request metadata' do
        post webhook_url, params: valid_payload.to_json, headers: headers
        
        webhook = RaceResultWebhook.last
        expect(webhook.source_ip).to be_present
      end
    end
    
    context 'with valid new raw data (timing) webhook' do
      let(:timing_payload) do
        {
          event_id: '12345',
          webhook_id: 'wr_xyz789',
          timestamp: '2025-11-09T14:25:30Z',
          trigger: 'new_raw_data',
          raw_data: {
            bib_number: '101',
            split_name: 'Mile 10',
            absolute_time: '2025-11-09T14:25:15Z',
            chip_time: '01:23:45',
            status: 'OK'
          }
        }
      end
      
      it 'creates a webhook record with timing data' do
        expect {
          post webhook_url, params: timing_payload.to_json, headers: headers
        }.to change(RaceResultWebhook, :count).by(1)
        
        webhook = RaceResultWebhook.last
        expect(webhook.trigger_type).to eq('new_raw_data')
        expect(webhook.bib_number).to eq('101')
        expect(webhook.split_name).to eq('Mile 10')
      end
      
      it 'returns success response' do
        post webhook_url, params: timing_payload.to_json, headers: headers
        
        expect(response).to have_http_status(:ok)
      end
    end
    
    context 'with participant update webhook' do
      let(:update_payload) do
        {
          event_id: '12345',
          webhook_id: 'wu_def456',
          timestamp: '2025-11-09T12:15:00Z',
          trigger: 'participant_update',
          participant: {
            bib_number: '101',
            status: 'DNS',
            updated_fields: ['status']
          }
        }
      end
      
      it 'creates a webhook record for update' do
        expect {
          post webhook_url, params: update_payload.to_json, headers: headers
        }.to change(RaceResultWebhook, :count).by(1)
        
        webhook = RaceResultWebhook.last
        expect(webhook.trigger_type).to eq('participant_update')
        expect(webhook.participant_data['status']).to eq('DNS')
      end
    end
    
    context 'with event setting change webhook' do
      let(:setting_payload) do
        {
          event_id: '12345',
          webhook_id: 'ws_ghi789',
          timestamp: '2025-11-09T09:00:00Z',
          trigger: 'event_file_setting_changed',
          settings: {
            event_name: 'Mountain Trail 100K',
            start_time: '2025-11-10T07:00:00Z'
          }
        }
      end
      
      it 'creates a webhook record for setting change' do
        expect {
          post webhook_url, params: setting_payload.to_json, headers: headers
        }.to change(RaceResultWebhook, :count).by(1)
        
        webhook = RaceResultWebhook.last
        expect(webhook.trigger_type).to eq('event_file_setting_changed')
      end
    end
    
    context 'with invalid JSON' do
      it 'handles parsing errors gracefully' do
        post webhook_url, params: 'invalid json', headers: headers
        
        # Should return error status
        expect(response).to have_http_status(:internal_server_error)
      end
    end
    
    context 'with missing required fields' do
      let(:incomplete_payload) do
        {
          webhook_id: 'incomplete'
        }
      end
      
      it 'handles gracefully' do
        post webhook_url, params: incomplete_payload.to_json, headers: headers
        
        # The log_webhook method should handle this gracefully
        expect([422, 500]).to include(response.status)
      end
    end
  end
  
  describe 'GET /api/v1/race_result_webhooks/status' do
    let(:status_url) { '/api/v1/race_result_webhooks/status' }
    
    it 'returns operational status' do
      get status_url
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['status']).to eq('operational')
      expect(json_response['service']).to eq('RaceResult Webhook Receiver')
    end
  end
end