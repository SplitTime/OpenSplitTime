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

    def self.perform!(event_group)
      new(event_group).perform!
    end

    def initialize(event_group)
      @event_group = event_group
      @response = ::Interactors::Response.new([])
      @time = Time.current
      validate_setup
    end

    def perform!
      events.each do |event|
        find_and_create_entrants(event)
        delete_obsolete_entrants(event)
      end

      response
    end

    private

    attr_reader :event_group, :response, :time

    def find_and_create_entrants(event)
      accepted_entrants = event.lottery.divisions.flat_map(&:accepted_entrants)
                               .sort_by { |entrant| [entrant.last_name, entrant.first_name] }

      accepted_entrants.find_each do |entrant|
        unique_key = { first_name: entrant.first_name, last_name: entrant.last_name, birthdate: entrant.birthdate }
        effort = event.efforts.find_or_initialize_by(unique_key)
        RELEVANT_ATTRIBUTES.each { |attr| effort.send("#{attr}=", entrant.send(attr)) }
        response.errors << resource_error_object(effort) unless effort.save
        effort.update_attribute(:synced_at, time)
      end
    end

    def delete_obsolete_entrants(event)
      obsolete_entrants = event.efforts.where.not(synced_at: time)
      obsolete_entrants.find_each(&:destroy)
    end

    def events
      @events ||= event_group.events.where.not(lottery_id: nil)
    end

    def validate_setup
      errors << events_not_linked_error unless events.present?
    end
  end
end