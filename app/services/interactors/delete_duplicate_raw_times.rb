# frozen_string_literal: true

module Interactors
  class DeleteDuplicateRawTimes
    include ActionView::Helpers::TextHelper
    include Interactors::Errors

    def self.perform!(event_group, scope = {})
      new(event_group, scope).perform!
    end

    def initialize(event_group, scope = {})
      @event_group = event_group
      @scope = scope
      @errors = []
    end

    def perform!
      self.pg_result = ActiveRecord::Base.connection.execute(query)
      errors << database_error("#{pg_result.cmd_status}: #{pg_result.error_message}") if query_unsuccessful?
      Interactors::Response.new(errors, message, {})
    end

    private

    attr_reader :event_group, :scope, :errors
    attr_accessor :pg_result

    def query
      RawTimeQuery.delete_duplicates(event_group, scope)
    end

    def query_unsuccessful?
      pg_result.error_message.present? || !(pg_result.cmd_status =~ /DELETE \d+/)
    end

    def deleted_raw_time_count
      pg_result.cmd_status.split.last
    end

    def message
      if errors.present?
        "Unable to delete duplicates"
      else
        "Deleted #{pluralize(deleted_raw_time_count, 'duplicate raw time')}"
      end
    end
  end
end
