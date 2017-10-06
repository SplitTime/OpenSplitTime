module Interactors
  class AssignPeopleToEfforts
    include Interactors::Errors

    def self.perform(id_hash)
      new(id_hash).perform
    end

    def initialize(id_hash)
      @id_hash = id_hash.transform_keys(&:to_i).transform_values(&:to_i)
      @errors = []
      @resources = {valid: [], invalid: []}
    end

    def perform
      id_hash.each do |effort_id, person_id|
        response = Interactors::AssignPersonToEffort.perform(people[person_id], efforts[effort_id])
        categorize(response)
      end
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :id_hash, :errors, :resources

    def efforts
      @efforts ||= Effort.where(id: id_hash.keys).index_by(&:id)
    end

    def people
      @people ||= Person.where(id: id_hash.values).index_by(&:id)
    end

    def categorize(response)
      if response.successful?
        response.resources.values.each { |response_resource| resources[:valid] << response_resource }
      else
        response.resources.values.each { |response_resource| resources[:invalid] << response_resource }
        response.errors.each { |response_error| errors << response_error }
      end
    end

    def response_message
      "#{id_hash.size} pairs were provided. #{resources[:valid].size} modified resources are valid. " +
          "#{resources[:invalid].size} modified resources are invalid."
    end
  end
end
