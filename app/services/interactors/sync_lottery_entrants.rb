# frozen_string_literal: true

module Interactors
  class SyncLotteryEntrants
    include ::Interactors::Errors
    include ::ActionView::Helpers::TextHelper

    RELEVANT_ATTRIBUTES = [
      "first_name",
      "last_name",
      "gender",
      "birthdate",
      "city",
      "state_code",
      "country_code",
    ].freeze

    def self.perform!(event, _current_user)
      new(event, _current_user).perform!
    end

    def self.preview(event, _current_user)
      new(event, _current_user).preview
    end

    def initialize(event, _current_user)
      @event = event
      @response = ::Interactors::Response.new([], nil, {})
      @time = Time.current
      @preview_only = false
      validate_setup
      set_response_resource_keys
    end

    def perform!
      return response if errors.present?

      find_and_create_entrants
      delete_obsolete_entrants

      set_response_message
      response
    end

    def preview
      self.preview_only = true

      perform!
    end

    private

    attr_reader :event, :response, :time
    attr_accessor :preview_only
    delegate :errors, :resources, to: :response, private: true

    def find_and_create_entrants
      lottery_connections = event.connections.from_service(:internal_lottery).where(source_type: "Lottery")
      connected_lotteries = Lottery.where(id: lottery_connections.map(&:source_id))
      accepted_entrants = connected_lotteries.flat_map(&:divisions).flat_map(&:accepted_entrants)
                            .sort_by { |entrant| [entrant.last_name, entrant.first_name] }

      accepted_entrants.each do |entrant|
        unique_key = { first_name: entrant.first_name, last_name: entrant.last_name, birthdate: entrant.birthdate }
        effort = event.efforts.find_or_initialize_by(unique_key)
        RELEVANT_ATTRIBUTES.each { |attr| effort.send("#{attr}=", entrant.send(attr)) }

        add_effort_to_response(effort)
        update_effort(effort) unless preview_only
      end
    end

    def add_effort_to_response(effort)
      if effort.new_record?
        resources[:created_efforts] << effort
      elsif effort.changed?
        resources[:updated_efforts] << effort
      else
        resources[:ignored_efforts] << effort
      end
    end

    def update_effort(effort)
      errors << resource_error_object(effort) unless effort.save
      effort.update_attribute(:synced_at, time)
    end

    def delete_obsolete_entrants
      retained_ids = (resources[:updated_efforts] + resources[:created_efforts] + resources[:ignored_efforts]).map(&:id)
      resources[:deleted_efforts] = event.efforts.where.not(id: retained_ids).to_a
      resources[:deleted_efforts].each(&:destroy) unless preview_only
    end

    def validate_setup
      errors << event_not_linked_error unless event.connections.from_service(:internal_lottery).where(source_type: "Lottery").exists?
    end

    def set_response_resource_keys
      resources[:created_efforts] = []
      resources[:updated_efforts] = []
      resources[:deleted_efforts] = []
      resources[:ignored_efforts] = []
    end

    def set_response_message
      response.message =
        if errors.present?
          "Sync resulted in errors"
        elsif preview_only
          "Preview was successful"
        else
          "Sync was successful"
        end
    end
  end
end
