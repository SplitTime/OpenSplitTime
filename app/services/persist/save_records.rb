# frozen_string_literal: true

module Persist

  # This class uses save to save any number of records in a single transaction, returning
  # a single Interactors::Response. This allows all callbacks and database constraints
  # to be respected.
  class SaveRecords < Persist::Base

    private

    def persist_resources
      resources.each do |record|
        record.save
        errors << resource_error_object(record) if record.invalid?
      end
    end
  end
end
