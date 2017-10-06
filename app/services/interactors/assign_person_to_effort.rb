module Interactors
  class AssignPersonToEffort
    include Interactors::Errors
    RELEVANT_ATTRIBUTES = [:first_name, :last_name, :gender, :birthdate, :email, :phone, :photo]

    def self.perform(person, effort)
      new(person, effort).perform
    end

    def initialize(person, effort)
      @person = person
      @effort = effort
      @errors = []
    end

    def perform
      Interactors::AssignGeoAttributes.perform(effort, person)
      effort.person = person
      assign_relevant_attributes
      validate_resources
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :person, :effort, :errors

    def assign_relevant_attributes
      RELEVANT_ATTRIBUTES.each do |attribute|
        person.assign_attributes(attribute => effort[attribute]) if person[attribute].blank?
      end
    end

    def validate_resources
      resources.values.each do |resource|
        unless resource.valid?
          errors << resource_error_object(resource)
        end
      end
    end

    def response_message
      errors.present? ? "#{person.full_name} was not assigned to effort #{effort}" : "#{person.full_name} was assigned to effort #{effort}"
    end

    def resources
      {person: person, effort: effort}
    end
  end
end
