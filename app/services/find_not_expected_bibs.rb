require "ostruct"

class FindNotExpectedBibs
  include Interactors::Errors
  include SplitAnalyzable

  def self.perform(event_group, split_name)
    new(event_group, split_name).perform
  end

  def initialize(event_group, split_name)
    @event_group = event_group
    @parameterized_split_name = split_name.parameterize
    @errors = []
    validate_setup
  end

  def perform
    OpenStruct.new(errors: errors, bib_numbers: bib_numbers)
  end

  private

  attr_reader :event_group, :parameterized_split_name, :errors

  def bib_numbers
    return [] if errors.present?

    query = EventGroupQuery.not_expected_bibs(event_group.id, split_name)
    ActiveRecord::Base.connection.execute(query).values.flatten
  end

  def validate_setup
    unless parameterized_split_names.include?(parameterized_split_name)
      errors << invalid_split_name_error(parameterized_split_name, parameterized_split_names)
    end
  end
end
