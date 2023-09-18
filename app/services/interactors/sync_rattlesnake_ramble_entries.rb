# frozen_string_literal: true

module Interactors
  class SyncRattlesnakeRambleEntries
    include ::Interactors::Errors

    RELEVANT_ATTRIBUTES = [
      "first_name",
      "last_name",
      "birthdate",
      "gender",
      "bib_number",
      "city",
      "state_code",
      "email",
      "scheduled_start_time",
    ].freeze

    def self.perform!(event, current_user)
      new(event, current_user).perform!
    end

    def self.preview(event, current_user)
      new(event, current_user).preview
    end

    def initialize(event, current_user)
      @event = event
      @current_user = current_user
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

    attr_reader :event, :current_user, :response, :time
    attr_accessor :preview_only
    delegate :errors, :resources, to: :response, private: true
    delegate :event_group, to: :event, private: true

    def find_and_create_entrants
      race_entries = race_edition_ids.flat_map do |race_edition_id|
        ::Connectors::RattlesnakeRamble::FetchRaceEntries.perform(race_edition_id: race_edition_id, user: current_user)
      end

      race_entries.sort_by! { |race_entry| [race_entry.racer.last_name, race_entry.racer.first_name] }

      race_entries.each do |race_entry|
        effort = event.efforts.where("first_name ilike ? and last_name ilike ?", race_entry.racer.first_name, race_entry.racer.last_name)
                      .where(birthdate: race_entry.racer.birth_date)
                      .first_or_initialize
        RELEVANT_ATTRIBUTES.each { |attr| effort.send("#{attr}=", race_entry.send(attr)) }

        add_effort_to_response(effort)
        update_effort(effort) unless preview_only
      end
    end

    def race_edition_ids
      @race_edition_ids ||=
        event.connections.from_service(:rattlesnake_ramble).where(source_type: "RaceEdition").pluck(:source_id)
    end

    def add_effort_to_response(effort)
      # Validate the effort first to get the effects of before_validation callbacks
      # like strip_attributes and capitalize_attributes
      effort.validate

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
      errors << event_not_linked_error unless event.connections.from_service(:rattlesnake_ramble).where(source_type: "RaceEdition").exists?
    end

    def set_response_message
      response.message = if errors.present?
                            "Sync completed with errors"
                          elsif preview_only
                            "Preview completed successfully"
                          else
                            "Sync completed successfully"
                         end
    end

    def set_response_resource_keys
      resources[:created_efforts] = []
      resources[:updated_efforts] = []
      resources[:deleted_efforts] = []
      resources[:ignored_efforts] = []
    end
  end
end
