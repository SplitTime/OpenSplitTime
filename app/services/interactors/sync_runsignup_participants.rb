# frozen_string_literal: true

module Interactors
  class SyncRunsignupParticipants
    include ::Interactors::Errors

    RELEVANT_ATTRIBUTES = [
      "first_name",
      "last_name",
      "gender",
      "birthdate",
      "city",
      "state_code",
      "country_code",
      "bib_number",
      "email",
      "phone",
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
      participants = runsignup_event_ids.flat_map do |runsignup_event_id|
        ::Runsignup::GetParticipants.perform(race_id: runsignup_race_id, event_id: runsignup_event_id, user: current_user)
      end

      participants.sort_by! { |participant| [participant.last_name, participant.first_name] }

      participants.each do |participant|
        effort = event.efforts.where("first_name ilike ? and last_name ilike ?", participant.first_name, participant.last_name)
                      .where(birthdate: participant.birthdate)
                      .first_or_initialize
        RELEVANT_ATTRIBUTES.each { |attr| effort.send("#{attr}=", participant.send(attr)) }

        add_effort_to_response(effort)
        update_effort(effort) unless preview_only
      end
    end

    def runsignup_event_ids
      @runsignup_event_ids ||=
        event.syncable_sources(:runsignup).where(source_type: "Event").pluck(:source_id)
    end

    def runsignup_race_id
      return @runsignup_race_id if defined?(@runsignup_race_id)

      ids = event_group.syncable_sources(:runsignup).where(source_type: "Race").pluck(:source_id)

      if ids.many?
        errors << multiple_runsignup_race_ids_error(ids, event_group.id)
        @runsignup_race_id = nil
      elsif ids.blank?
        errors << no_runsignup_race_id_error(event_group.id)
        @runsignup_race_id = nil
      else
        @runsignup_race_id = ids.first
      end
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
      errors << event_not_linked_error unless event.lottery.present?
    end

    def set_response_resource_keys
      resources[:created_efforts] = []
      resources[:updated_efforts] = []
      resources[:deleted_efforts] = []
      resources[:ignored_efforts] = []
    end
  end
end
