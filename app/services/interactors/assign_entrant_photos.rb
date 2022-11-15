# frozen_string_literal: true

module Interactors
  class AssignEntrantPhotos
    include Interactors::Errors

    def self.perform!(event_group)
      new(event_group).perform!
    end

    def initialize(event_group)
      @event_group = event_group
      @response = ::Interactors::Response.new([])
    end

    def perform!
      event_group.entrant_photos.includes(:blob).find_each do |entrant_photo|
        filename = entrant_photo.blob.filename.to_s
        bib_number = filename.delete("^0-9")

        if bib_number.blank?
          response.errors << invalid_filename_error(filename)
          next
        end

        effort = event_group.efforts.find_by(bib_number: bib_number)

        if effort.blank?
          response.errors << bib_not_found_error(bib_number, filename)
          next
        end

        effort.photo.purge_later
        entrant_photo.update(name: "photo", record_type: "Effort", record_id: effort.id)
      end

      response
    end

    private

    attr_reader :event_group, :response
  end
end
