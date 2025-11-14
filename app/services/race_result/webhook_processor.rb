# frozen_string_literal: true

module RaceResult
  class WebhookProcessor
    attr_reader :webhook, :errors
    
    def initialize(webhook)
      @webhook = webhook
      @errors = []
    end
    
    def self.call(webhook)
      new(webhook).call
    end
    
    def call
      return false unless webhook.is_a?(RaceResultWebhook)
      
      webhook.mark_as_processing!
      
      case webhook.trigger_type
      when 'new_participant'
        process_new_participant
      when 'participant_update'
        process_participant_update
      when 'new_raw_data'
        process_new_raw_data
      when 'event_file_setting_changed'
        process_event_setting_change
      else
        log_unknown_trigger
      end
      
      if errors.empty?
        webhook.mark_as_processed!
        true
      else
        webhook.mark_as_failed!(StandardError.new(errors.join('; ')))
        false
      end
    rescue StandardError => e
      webhook.mark_as_failed!(e)
      Rails.logger.error("Error processing webhook #{webhook.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      false
    end
    
    private
    
    def process_new_participant
      # TODO: Future implementation
      # This would create or update an Effort record based on participant data
      # 
      # Example logic:
      # - Find or create person based on name and identifying info
      # - Find or create effort for the event
      # - Update bib number, demographics, etc.
      
      log_info("Processing new participant: #{webhook.bib_number}")
      
      # Placeholder for future implementation
      log_info("Participant data logged. Integration pending.")
    end
    
    def process_participant_update
      # TODO: Future implementation
      # This would update an existing Effort record
      #
      # Example logic:
      # - Find effort by bib number and event
      # - Update changed fields
      # - Handle status changes (DNS, DNF, etc.)
      
      log_info("Processing participant update: #{webhook.bib_number}")
      
      # Placeholder for future implementation
      log_info("Participant update logged. Integration pending.")
    end
    
    def process_new_raw_data
      # TODO: Future implementation
      # This would create a SplitTime record from timing data
      #
      # Example logic:
      # - Find effort by bib number
      # - Find split by name
      # - Create or update split_time record
      # - Calculate elapsed time
      
      log_info("Processing new raw data: Bib #{webhook.bib_number}, " \
               "Split #{webhook.split_name}, Time #{webhook.absolute_time}")
      
      # Placeholder for future implementation
      log_info("Timing data logged. Integration pending.")
    end
    
    def process_event_setting_change
      # TODO: Future implementation
      # This would update Event or Course settings
      #
      # Example logic:
      # - Find event by RaceResult event_id
      # - Update relevant settings
      # - Sync course information if needed
      
      log_info("Processing event setting change for event: #{webhook.event_id}")
      
      # Placeholder for future implementation
      log_info("Event setting change logged. Integration pending.")
    end
    
    def log_unknown_trigger
      message = "Unknown webhook trigger type: #{webhook.trigger_type}"
      log_warning(message)
      @errors << message
    end
    
    def log_info(message)
      Rails.logger.info("[RaceResult::WebhookProcessor] #{message}")
    end
    
    def log_warning(message)
      Rails.logger.warn("[RaceResult::WebhookProcessor] #{message}")
    end
    
    # Helper methods for future implementation
    
    def find_or_create_effort
      # Logic to find or create effort based on webhook data
      # This would use webhook.bib_number and webhook.event_id
    end
    
    def find_split_by_name(split_name)
      # Logic to find split by name within the event's course
    end
    
    def participant_attributes
      data = webhook.participant_data
      {
        bib_number: data['bib_number'],
        first_name: data['first_name'],
        last_name: data['last_name'],
        email: data['email'],
        gender: map_gender(data['gender']),
        age: data['age'],
        city: data['city'],
        state_code: data['state'],
        country_code: data['country']
      }.compact
    end
    
    def map_gender(race_result_gender)
      case race_result_gender&.upcase
      when 'M', 'MALE'
        'male'
      when 'F', 'FEMALE'
        'female'
      else
        nil
      end
    end
  end
end