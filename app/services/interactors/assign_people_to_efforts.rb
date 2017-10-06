module Interactors
  class AssignPeopleToEfforts
    include Interactors::Errors

    def self.perform!(id_hash)
      new(id_hash).perform!
    end

    def initialize(id_hash)
      @id_hash = id_hash.transform_keys(&:to_i).transform_values(&:to_i)
      @errors = []
      @resources = {saved: [], unsaved: []}
    end

    def perform!
      id_hash.each do |effort_id, person_id|
        assign_response = Interactors::AssignPersonToEffort.perform(people[person_id], efforts[effort_id])
        save_and_categorize(assign_response)
      end
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :id_hash, :errors, :resources

    def people
      @people ||= Person.where(id: id_hash.values).index_by(&:id)
    end

    def efforts
      @efforts ||= Effort.where(id: id_hash.keys).index_by(&:id)
    end

    def save_and_categorize(assign_response)
      person_effort_hash = assign_response.resources
      ActiveRecord::Base.transaction do
        if person_effort_hash.values.all? { |resource| resource.save }
          resources[:saved] << person_effort_hash
        else
          resources[:unsaved] << person_effort_hash
          person_effort_hash.values.select(&:invalid?).each { |invalid_resource| errors << resource_error_object(invalid_resource) }
          raise ActiveRecord::Rollback
        end
      end
    end

    def response_message
      errors.present? ? [attempted_message, succeeded_message, failed_message].join : succeeded_message
    end

    def attempted_message
      id_hash.size > 2 ? "Attempted to reconcile #{id_hash.size} efforts. " : ''
    end

    def succeeded_message
      resources[:saved].one? ? "Reconciled #{resources[:saved].first[:effort].full_name}. " :
          "Reconciled #{resources[:saved].size} efforts. "
    end

    def failed_message
      resources[:unsaved].one? ? "Could not reconcile #{resources[:unsaved].first[:effort].full_name} with #{resources[:unsaved].first[:person].full_name}. " :
          "#{resources[:unsaved].size} efforts could not be reconciled. "
    end
  end
end
