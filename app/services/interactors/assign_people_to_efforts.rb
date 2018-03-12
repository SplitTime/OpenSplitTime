# frozen_string_literal: true

module Interactors
  class AssignPeopleToEfforts
    include Interactors::Errors
    PERSONAL_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone, :photo]

    def self.perform!(id_hash)
      new(id_hash).perform!
    end

    def initialize(id_hash)
      @id_hash = id_hash.transform_keys(&:to_i).transform_values { |person_id| person_id.to_i if person_id }
      @errors = []
      @resources = {saved: [], unsaved: []}
    end

    def perform!
      id_hash.each do |effort_id, person_id|
        pull_response = find_and_pull_attributes(effort_id, person_id)
        save_and_categorize(effort: pull_response.resources[:source], person: pull_response.resources[:destination])
      end
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :id_hash, :errors, :resources

    def find_and_pull_attributes(effort_id, person_id)
      person = person_id ? people[person_id] : Person.new
      effort = efforts[effort_id]
      effort.person = person
      Interactors::PullAttributes.perform(effort, person, PERSONAL_ATTRIBUTES)
      Interactors::PullGeoAttributes.perform(effort, person)
    end

    def people
      @people ||= Person.find(id_hash.values).index_by(&:id)
    end

    def efforts
      @efforts ||= Effort.find(id_hash.keys).index_by(&:id)
    end

    def save_and_categorize(modified_resources)
      ActiveRecord::Base.transaction do
        if modified_resources.values.all? { |resource| resource.save }
          resources[:saved] << modified_resources
        else
          resources[:unsaved] << modified_resources
          modified_resources.values.select(&:invalid?).each { |invalid_resource| errors << resource_error_object(invalid_resource) }
          raise ActiveRecord::Rollback
        end
      end
    end

    def response_message
      if errors.present?
        [attempted_message, succeeded_message, failed_message].join
      elsif id_hash.size == 0
        "No pairs were provided. "
      else
        succeeded_message
      end
    end

    def attempted_message
      id_hash.size > 2 ? "Attempted to reconcile #{id_hash.size} efforts. " : ''
    end

    def succeeded_message
      case resources[:saved].size
      when 0
        "No records were created. "
      when 1
        "Reconciled #{resources[:saved].first[:person].full_name} with #{resources[:saved].first[:effort].full_name}. "
      else
        "Reconciled #{resources[:saved].size} efforts. "
      end
    end

    def failed_message
      case resources[:unsaved].size
      when 0
        "No records failed to reconcile. "
      when 1
        "Could not reconcile #{resources[:unsaved].first[:person].full_name} with #{resources[:unsaved].first[:effort].full_name}. "
      else
        "#{resources[:unsaved].size} efforts could not be reconciled. "
      end
    end
  end
end
