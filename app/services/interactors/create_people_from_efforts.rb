# frozen_string_literal: true

module Interactors
  class CreatePeopleFromEfforts
    include Interactors::Errors

    def self.perform!(effort_ids)
      new(effort_ids).perform!
    end

    def initialize(effort_ids)
      @id_hash = effort_ids.zip(Array.new(effort_ids.size)).to_h
    end

    def perform!
      self.response = Interactors::AssignPeopleToEfforts.perform!(id_hash)
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :id_hash
    attr_accessor :response
    delegate :errors, :resources, to: :response

    def response_message
      if errors.present?
        [attempted_message, succeeded_message, failed_message].join
      elsif id_hash.size == 0
        "No efforts were provided. "
      else
        succeeded_message
      end
    end

    def attempted_message
      id_hash.size > 2 ? "Attempted to create #{id_hash.size} new records. " : ''
    end

    def succeeded_message
      case resources[:saved].size
      when 0
        "No records were created. "
      when 1
        "Created and reconciled #{resources[:saved].first[:person].full_name} as a new record. "
      else
        "Created and reconciled #{resources[:saved].size} new records. "
      end
    end

    def failed_message
      case resources[:unsaved].size
      when 0
        "No records failed to create. "
      when 1
        "Could not create #{resources[:unsaved].first[:person].full_name}. "
      else
        "#{resources[:unsaved].size} records could not be created. "
      end
    end
  end
end
