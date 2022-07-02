# frozen_string_literal: true

module Interactors
  class BulkSetBibNumbers
    include Errors

    # @param [::EventGroup] event_group
    # @param [::Hash] bib_assignments
    # @return [::Interactors::Response]
    def self.perform!(event_group, bib_assignments)
      new(event_group, bib_assignments).perform!
    end

    # @param [::EventGroup] event_group
    # @param [Hash] bib_assignments
    def initialize(event_group, bib_assignments)
      @event_group = event_group
      @bib_assignments = bib_assignments
      @response = ::Interactors::Response.new([])
    end

    # @return [::Interactors::Response]
    def perform!
      ::ActiveRecord::Base.transaction do
        bib_assignments.each do |effort_id, bib_number|
          event_group.efforts.where(id: effort_id).update_all(bib_number: bib_number)
          event_group.efforts.where.not(id: effort_id).where(bib_number: bib_number).update_all(bib_number: nil)
        end
      rescue ActiveRecordError => error
        response.errors << active_record_error(error)
        raise ::ActiveRecord::Rollback
      ensure
        duplicate_bib_numbers = event_group.efforts.select(:bib_number).where.not(bib_number: nil).group(:bib_number).having("count(*) > 1").pluck(:bib_number)

        if duplicate_bib_numbers.present?
          response.errors << duplicate_bib_numbers_error(duplicate_bib_numbers)
          raise ::ActiveRecord::Rollback
        else
          empty_efforts = event_group.efforts.where(id: bib_assignments.keys).where(bib_number: nil)

          if empty_efforts.exists?
            problem_efforts = empty_efforts.select(:id, :last_name).map { |effort| [effort.last_name, bib_assignments[effort.id]] }
            response.errors << empty_bib_numbers_error(problem_efforts)
          end
        end
      end

      response
    end

    private

    attr_reader :event_group, :bib_assignments, :response

    # @return [Array<String>]
    def effort_ids
      @effort_ids ||= event_group.efforts.pluck(:id)
    end

    # @return [Hash]
    def relevant_bib_assignments
      bib_assignments.slice(*effort_ids)
    end
  end
end
