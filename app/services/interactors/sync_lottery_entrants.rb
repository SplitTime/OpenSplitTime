# frozen_string_literal: true

module Interactors
  class SyncLotteryEntrants
    include ::Interactors::Errors

    RELEVANT_ATTRIBUTES = [
      "first_name",
      "last_name",
      "gender",
      "birthdate",
      "city",
      "state_code",
      "country_code",
    ].freeze

    def self.perform!(event)
      new(event).perform!
    end

    def initialize(event)
      @event = event
      @response = ::Interactors::Response.new([])
      @time = Time.current
      validate_setup
    end

    def perform!
      return response if errors.present?

      find_and_create_entrants
      delete_obsolete_entrants

      response
    end

    private

    attr_reader :event, :response, :time
    delegate :errors, to: :response, private: true

    def find_and_create_entrants
      accepted_entrants = event.lottery.divisions.flat_map(&:accepted_entrants)
                               .sort_by { |entrant| [entrant.last_name, entrant.first_name] }

      accepted_entrants.each do |entrant|
        unique_key = { first_name: entrant.first_name, last_name: entrant.last_name, birthdate: entrant.birthdate }
        effort = event.efforts.find_or_initialize_by(unique_key)
        RELEVANT_ATTRIBUTES.each { |attr| effort.send("#{attr}=", entrant.send(attr)) }
        errors << resource_error_object(effort) unless effort.save
        effort.update_attribute(:synced_at, time)
      end
    end

    def delete_obsolete_entrants
      obsolete_entrants = event.efforts.where("synced_at is null or synced_at != ?", time)
      obsolete_entrants.find_each(&:destroy)
    end

    def validate_setup
      errors << event_not_linked_error unless event.lottery.present?
    end
  end
end
