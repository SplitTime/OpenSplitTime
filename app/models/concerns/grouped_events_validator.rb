# frozen_string_literal: true

class GroupedEventsValidator < ActiveModel::Validator
  def validate(event_group)
    @event_group = event_group
    @analyzer = EventGroupSplitAnalyzer.new(event_group)
    validate_bibs
    validate_split_locations
  end

  private

  attr_reader :event_group, :analyzer
  delegate :events, to: :event_group
  delegate :incompatible_locations, to: :analyzer

  def validate_bibs
    efforts_with_bibs = Effort.where(event: events).where.not(bib_number: nil).select(:bib_number)
    if efforts_with_bibs.size != efforts_with_bibs.distinct.size
      duplicate_bib_numbers = efforts_with_bibs.pluck(:bib_number).count_by(&:itself)
                                  .select { |_, count| count > 1 }.keys.uniq.sort
      dup_size = duplicate_bib_numbers.size
      event_group.errors.add(:base, "Bib #{'number'.pluralize(dup_size)} #{duplicate_bib_numbers.to_sentence} #{'is'.pluralize(dup_size)} duplicated within the event group")
    end
  end

  def validate_split_locations
    if incompatible_locations.present?
      size = incompatible_locations.size
      locations = incompatible_locations.map(&:titleize).to_sentence
      event_group.errors.add(:base, "#{'Location'.pluralize(size)} #{locations} #{'is'.pluralize(size)} " +
          "incompatible within the event group. Splits with duplicate names must have the same locations. ")
    end
  end
end
