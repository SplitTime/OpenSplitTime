# frozen_string_literal: true

module Interactors
  class PullAttributes
    def self.perform(source, destination, attributes)
      new(source, destination, attributes).perform
    end

    def initialize(source, destination, attributes)
      @source = source
      @destination = destination
      @attributes = attributes
      @errors = []
    end

    def perform
      assign_relevant_attributes
      Interactors::Response.new(errors, response_message, resources)
    end

    private

    attr_reader :source, :destination, :attributes, :errors

    def assign_relevant_attributes
      attributes.each do |attribute|
        destination.assign_attributes(attribute => source[attribute]) if destination[attribute].blank?
      end
    end

    def response_message
      "#{attributes.join(', ')} for #{destination.class} #{destination.full_name} were pulled from #{source.class} #{source}"
    end

    def resources
      {source: source, destination: destination}
    end
  end
end
