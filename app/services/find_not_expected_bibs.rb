# frozen_string_literal: true

class FindNotExpectedBibs
  include Interactors::Errors

  def self.perform(event_group, split_name)
    new(event_group, split_name).perform
  end

  def initialize(event_group, split_name)
    @event_group = event_group
    @split_name = split_name.parameterize
    @errors = []
    validate_setup
  end

  def perform
    OpenStruct.new(errors: errors, bib_numbers: bib_numbers)
  end

  private

  attr_reader :event_group, :split_name, :errors

  def bib_numbers
    return [] if errors.present?
    event_group.not_expected_bibs(split_name)
  end

  def ordered_split_names
    @ordered_split_names ||= event_group.ordered_split_names
  end

  def validate_setup
    unless ordered_split_names.include?(split_name)
      errors << invalid_split_name_error(split_name, ordered_split_names)
    end
  end
end
